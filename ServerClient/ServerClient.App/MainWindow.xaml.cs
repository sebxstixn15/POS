using System;
using System.Windows;
using System.Windows.Input;
using ServerClient.App.Network;
using ServerClient.Shared.Models;
using ServerClient.Shared.Protocol;

namespace ServerClient.App
{
    public partial class MainWindow : Window
    {
        // ── Server-Felder ─────────────────────────────────────
        private TcpServer? _server;

        // ── Client-Felder ─────────────────────────────────────
        private ServerConnection? _connection;
        private string? _clientName;

        public MainWindow()
        {
            InitializeComponent();
        }

        // ══════════════════════════════════════════════════════
        //  STARTBILDSCHIRM
        // ══════════════════════════════════════════════════════

        private void BtnStartMode_Click(object sender, RoutedEventArgs e)
        {
            PnlStart.Visibility = Visibility.Collapsed;

            if (CmbMode.SelectedIndex == 0)
            {
                // Server-Modus
                PnlServer.Visibility = Visibility.Visible;
                Title = "Server-Client – SERVER";
            }
            else
            {
                // Client-Modus
                PnlClient.Visibility = Visibility.Visible;
                Title = "Server-Client – CLIENT";
            }
        }

        // ══════════════════════════════════════════════════════
        //  SERVER
        // ══════════════════════════════════════════════════════

        private void BtnServerStart_Click(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(TxtServerPort.Text, out int port) || port < 1 || port > 65535)
            {
                MessageBox.Show("Ungültiger Port (1–65535).", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                _server = new TcpServer();
                _server.OnLog += AppendServerLog;
                _server.OnMessageReceived += msg =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        LstServerMessages.Items.Add(msg.ToString());
                        LstServerMessages.ScrollIntoView(LstServerMessages.Items[^1]);
                    });
                };
                _server.Start(port);

                LblServerStatus.Content = $"Läuft auf Port {port}";
                LblServerStatus.Foreground = System.Windows.Media.Brushes.Green;
                BtnServerStart.IsEnabled = false;
                BtnServerStop.IsEnabled = true;
                TxtServerPort.IsEnabled = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Fehler beim Starten: {ex.Message}", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnServerStop_Click(object sender, RoutedEventArgs e)
        {
            _server?.Stop();
            _server = null;

            LblServerStatus.Content = "Gestoppt";
            LblServerStatus.Foreground = System.Windows.Media.Brushes.Red;
            BtnServerStart.IsEnabled = true;
            BtnServerStop.IsEnabled = false;
            TxtServerPort.IsEnabled = true;
        }

        private void AppendServerLog(string message)
        {
            Dispatcher.Invoke(() =>
            {
                LstServerLog.Items.Add(message);
                LstServerLog.ScrollIntoView(LstServerLog.Items[^1]);
                TxtServerStats.Text = $"Verbundene Clients: {_server?.ClientCount ?? 0}";
            });
        }

        private void BtnClearServerLog_Click(object sender, RoutedEventArgs e)
        {
            LstServerLog.Items.Clear();
        }

        // ══════════════════════════════════════════════════════
        //  CLIENT
        // ══════════════════════════════════════════════════════

        private async void BtnClientConnect_Click(object sender, RoutedEventArgs e)
        {
            var host = TxtClientHost.Text.Trim();
            var name = TxtClientName.Text.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                MessageBox.Show("Bitte einen Benutzernamen eingeben.", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!int.TryParse(TxtClientPort.Text, out int port) || port < 1 || port > 65535)
            {
                MessageBox.Show("Ungültiger Port (1–65535).", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                _connection = new ServerConnection();
                _connection.PacketReceived += OnClientPacketReceived;
                _connection.Disconnected += () =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        SetClientConnected(false);
                        LstClientMessages.Items.Add("[System] Verbindung zum Server verloren.");
                    });
                };

                await _connection.ConnectAsync(host, port);

                _clientName = name;

                // Connect-Paket senden (mit Benutzername)
                _connection.Send(Packet.Create(PacketType.Connect, name));

                LstClientMessages.Items.Add($"[System] Verbindung wird hergestellt...");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Verbindung fehlgeschlagen: {ex.Message}", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnClientPacketReceived(Packet packet)
        {
            Dispatcher.Invoke(() =>
            {
                switch (packet.Type)
                {
                    case PacketType.ConnectResponse:
                        var response = packet.GetPayload<string>();
                        LstClientMessages.Items.Add($"[Server] {response}");
                        SetClientConnected(true);
                        break;

                    case PacketType.MessageReceived:
                        var msg = packet.GetPayload<Message>();
                        if (msg != null)
                            LstClientMessages.Items.Add(msg.ToString());
                        break;

                    case PacketType.ClientJoined:
                        var joinedName = packet.GetPayload<string>();
                        LstClientMessages.Items.Add($"[System] {joinedName} hat sich verbunden.");
                        break;

                    case PacketType.ClientLeft:
                        var leftName = packet.GetPayload<string>();
                        LstClientMessages.Items.Add($"[System] {leftName} hat sich getrennt.");
                        break;

                    case PacketType.Error:
                        var error = packet.GetPayload<string>();
                        LstClientMessages.Items.Add($"[Fehler] {error}");
                        _connection?.Disconnect();
                        SetClientConnected(false);
                        break;
                }

                // Auto-Scroll
                if (LstClientMessages.Items.Count > 0)
                    LstClientMessages.ScrollIntoView(LstClientMessages.Items[^1]);
            });
        }

        private void SetClientConnected(bool connected)
        {
            BtnClientConnect.IsEnabled = !connected;
            BtnClientDisconnect.IsEnabled = connected;
            TxtClientHost.IsEnabled = !connected;
            TxtClientPort.IsEnabled = !connected;
            TxtClientName.IsEnabled = !connected;
            TxtClientMessage.IsEnabled = connected;
            BtnClientSend.IsEnabled = connected;

            LblClientStatus.Content = connected ? "Verbunden" : "Getrennt";
            LblClientStatus.Foreground = connected
                ? System.Windows.Media.Brushes.Green
                : System.Windows.Media.Brushes.Red;

            if (connected)
                TxtClientMessage.Focus();
        }

        private void BtnClientSend_Click(object sender, RoutedEventArgs e)
        {
            SendClientMessage();
        }

        private void TxtClientMessage_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
                SendClientMessage();
        }

        private void SendClientMessage()
        {
            var text = TxtClientMessage.Text.Trim();
            if (string.IsNullOrWhiteSpace(text) || _connection == null) return;

            var message = new Message
            {
                SenderName = _clientName!,
                Content = text,
                Timestamp = DateTime.Now
            };

            _connection.Send(Packet.Create(PacketType.SendMessage, message));
            TxtClientMessage.Clear();
        }

        private void BtnClientDisconnect_Click(object sender, RoutedEventArgs e)
        {
            _connection?.Send(Packet.Create(PacketType.Disconnect));
            _connection?.Disconnect();
            _connection = null;
            SetClientConnected(false);
            LstClientMessages.Items.Add("[System] Verbindung getrennt.");
        }

        // ══════════════════════════════════════════════════════
        //  WINDOW CLOSING
        // ══════════════════════════════════════════════════════

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            _server?.Stop();
            _connection?.Disconnect();
        }
    }
}
