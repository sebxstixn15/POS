using System;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using ServerClient.Shared.Protocol;

namespace ServerClient.App.Network
{
    /// <summary>
    /// Die Verbindung vom Client zum Server.
    /// Sendet und empfängt Pakete über TCP.
    /// </summary>
    public class ServerConnection
    {
        private TcpClient? _client;
        private StreamReader? _reader;
        private StreamWriter? _writer;
        private readonly object _writeLock = new();
        private bool _running;
        private bool _intentionalDisconnect;

        /// <summary>Wird aufgerufen wenn ein Paket vom Server empfangen wird.</summary>
        public event Action<Packet>? PacketReceived;

        /// <summary>Wird aufgerufen wenn die Verbindung unerwartet getrennt wird.</summary>
        public event Action? Disconnected;

        public bool IsConnected => _client?.Connected ?? false;

        /// <summary>Stellt eine Verbindung zum Server her.</summary>
        public async Task ConnectAsync(string host, int port)
        {
            _intentionalDisconnect = false;
            _client = new TcpClient();
            _client.NoDelay = true;
            await _client.ConnectAsync(host, port);

            var stream = _client.GetStream();
            _reader = new StreamReader(stream, Encoding.UTF8);
            _writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true };
            _running = true;
            _ = Task.Run(ReceiveLoop);
        }

        /// <summary>Empfangsschleife – liest Pakete vom Server.</summary>
        private async Task ReceiveLoop()
        {
            try
            {
                string? line;
                while (_running && (line = await _reader!.ReadLineAsync()) != null)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var packet = Packet.FromJson(line);
                    if (packet != null)
                        PacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { /* Verbindung geschlossen */ }
            catch (Exception) { /* Andere Fehler */ }
            finally
            {
                _running = false;
                if (!_intentionalDisconnect)
                    Disconnected?.Invoke();
            }
        }

        /// <summary>Sendet ein Paket an den Server.</summary>
        public void Send(Packet packet)
        {
            try
            {
                lock (_writeLock)
                    _writer?.WriteLine(packet.ToJson());
            }
            catch { }
        }

        /// <summary>Trennt die Verbindung zum Server.</summary>
        public void Disconnect()
        {
            _intentionalDisconnect = true;
            _running = false;
            try { _client?.Close(); } catch { }
        }
    }
}
