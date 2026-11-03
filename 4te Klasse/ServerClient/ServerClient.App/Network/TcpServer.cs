using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using ServerClient.Shared.Models;
using ServerClient.Shared.Protocol;

namespace ServerClient.App.Network
{
    /// <summary>
    /// Der TCP-Server. Wartet auf neue Verbindungen und verwaltet alle verbundenen Clients.
    /// </summary>
    public class TcpServer
    {
        private TcpListener? _listener;
        private bool _running;

        private readonly List<ConnectedClient> _clients = new();
        private readonly object _lock = new();

        /// <summary>Wird aufgerufen wenn etwas geloggt werden soll.</summary>
        public event Action<string>? OnLog;

        /// <summary>Wird aufgerufen wenn eine Message empfangen wird.</summary>
        public event Action<Message>? OnMessageReceived;

        // ── Start / Stop ──────────────────────────────────────

        public void Start(int port)
        {
            _listener = new TcpListener(IPAddress.Any, port);
            _listener.Start();
            _running = true;
            Log($"Server gestartet auf Port {port}");
            Task.Run(AcceptConnections);
        }

        public void Stop()
        {
            _running = false;

            // Alle Clients trennen
            lock (_lock)
            {
                foreach (var c in _clients)
                    c.Close();
                _clients.Clear();
            }

            _listener?.Stop();
            Log("Server gestoppt.");
        }

        /// <summary>Wartet in einer Schleife auf neue Client-Verbindungen.</summary>
        private async Task AcceptConnections()
        {
            while (_running)
            {
                try
                {
                    var tcpClient = await _listener!.AcceptTcpClientAsync();
                    Log($"Neue Verbindung von {tcpClient.Client.RemoteEndPoint}");

                    var client = new ConnectedClient(tcpClient);
                    client.OnPacketReceived += packet => HandlePacket(client, packet);
                    client.OnDisconnected += () => HandleDisconnect(client);
                    client.StartReceiving();
                }
                catch
                {
                    if (!_running) break;
                }
            }
        }

        // ── Paket-Verarbeitung ────────────────────────────────

        private void HandlePacket(ConnectedClient client, Packet packet)
        {
            switch (packet.Type)
            {
                case PacketType.Connect:
                    HandleConnect(client, packet);
                    break;

                case PacketType.SendMessage:
                    HandleMessage(client, packet);
                    break;

                case PacketType.Disconnect:
                    HandleDisconnect(client);
                    break;
            }
        }

        private void HandleConnect(ConnectedClient client, Packet packet)
        {
            var name = packet.GetPayload<string>();
            if (string.IsNullOrWhiteSpace(name))
            {
                client.Send(Packet.Create(PacketType.Error, "Benutzername darf nicht leer sein."));
                return;
            }

            // Prüfen ob Name schon vergeben
            lock (_lock)
            {
                if (_clients.Any(c => c.Name == name))
                {
                    client.Send(Packet.Create(PacketType.Error, $"Name '{name}' ist bereits vergeben."));
                    return;
                }
            }

            client.Name = name;

            lock (_lock)
                _clients.Add(client);

            // Bestätigung an den Client
            client.Send(Packet.Create(PacketType.ConnectResponse, "Verbindung erfolgreich."));

            Log($"Client verbunden: {name} ({client.RemoteEndPoint})");

            // Alle anderen informieren
            BroadcastExcept(Packet.Create(PacketType.ClientJoined, name), client);
        }

        private void HandleMessage(ConnectedClient client, Packet packet)
        {
            var msg = packet.GetPayload<Message>();
            if (msg == null || !client.IsConnected) return;

            // Absender-Name vom Server setzen (nicht dem Client vertrauen)
            msg.SenderName = client.Name!;
            msg.Timestamp = DateTime.Now;

            Log($"Nachricht von {msg.SenderName}: {msg.Content}");

            // Event für die Server-UI
            OnMessageReceived?.Invoke(msg);

            // An alle Clients weiterleiten (inkl. Absender)
            Broadcast(Packet.Create(PacketType.MessageReceived, msg));
        }

        private void HandleDisconnect(ConnectedClient client)
        {
            if (client.Name == null) return;

            var name = client.Name;
            lock (_lock)
                _clients.Remove(client);

            client.Close();
            Log($"Client getrennt: {name}");

            // Alle informieren
            Broadcast(Packet.Create(PacketType.ClientLeft, name));
        }

        // ── Broadcast ─────────────────────────────────────────

        /// <summary>Sendet ein Paket an alle verbundenen Clients.</summary>
        private void Broadcast(Packet packet)
        {
            lock (_lock)
                foreach (var c in _clients.Where(c => c.IsConnected))
                    c.Send(packet);
        }

        /// <summary>Sendet ein Paket an alle außer einem bestimmten Client.</summary>
        private void BroadcastExcept(Packet packet, ConnectedClient except)
        {
            lock (_lock)
                foreach (var c in _clients.Where(c => c.IsConnected && c != except))
                    c.Send(packet);
        }

        // ── Logging ───────────────────────────────────────────

        public void Log(string message)
        {
            var line = $"[{DateTime.Now:HH:mm:ss}] {message}";
            OnLog?.Invoke(line);
        }

        /// <summary>Gibt die Anzahl verbundener Clients zurück.</summary>
        public int ClientCount
        {
            get { lock (_lock) return _clients.Count; }
        }
    }

    /// <summary>
    /// Repräsentiert einen verbundenen Client auf der Server-Seite.
    /// </summary>
    public class ConnectedClient
    {
        private readonly TcpClient _tcpClient;
        private readonly StreamReader _reader;
        private readonly StreamWriter _writer;
        private readonly object _sendLock = new();
        private bool _running;

        public string? Name { get; set; }
        public bool IsConnected => Name != null;
        public string? RemoteEndPoint => _tcpClient.Client.RemoteEndPoint?.ToString();

        public event Action<Packet>? OnPacketReceived;
        public event Action? OnDisconnected;

        public ConnectedClient(TcpClient client)
        {
            _tcpClient = client;
            _tcpClient.NoDelay = true;

            var stream = client.GetStream();
            _reader = new StreamReader(stream, Encoding.UTF8);
            _writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true };
        }

        public void StartReceiving()
        {
            _running = true;
            Task.Run(ReceiveLoop);
        }

        private async Task ReceiveLoop()
        {
            try
            {
                string? line;
                while (_running && (line = await _reader.ReadLineAsync()) != null)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var packet = Packet.FromJson(line);
                    if (packet != null)
                        OnPacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { /* Verbindung geschlossen */ }
            catch (Exception) { /* Andere Fehler */ }
            finally
            {
                _running = false;
                OnDisconnected?.Invoke();
            }
        }

        public void Send(Packet packet)
        {
            try
            {
                lock (_sendLock)
                    _writer.WriteLine(packet.ToJson());
            }
            catch { /* Client nicht mehr erreichbar */ }
        }

        public void Close()
        {
            _running = false;
            try { _tcpClient.Close(); } catch { }
        }
    }
}
