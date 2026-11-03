using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using TcpWpfApp.Models;
using System.Collections.ObjectModel;

namespace TcpWpfApp
{
    public partial class MainWindow : Window
    {
        private TcpListener? _server;
        private TcpClient? _client;
        private StreamReader? _reader;
        private StreamWriter? _writer;
        private CancellationTokenSource? _cancellationTokenSource;
        
        public ObservableCollection<Message> ChatMessages { get; set; } = new ObservableCollection<Message>();

        public MainWindow()
        {
            InitializeComponent();
            ChatListBox.ItemsSource = ChatMessages;
        }

        private async void StartServerBtn_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                int port = int.Parse(PortTextBox.Text);
                _server = new TcpListener(IPAddress.Any, port);
                _server.Start();
                
                StartServerBtn.IsEnabled = false;
                ConnectClientBtn.IsEnabled = false;
                
                AddLogMessage("System", $"Server gestartet auf Port {port}. Warte auf Verbindung...");

                // Warte asynchron auf einen Client, damit die UI nicht einfriert
                _client = await _server.AcceptTcpClientAsync();
                AddLogMessage("System", "Ein Client hat sich verbunden!");
                
                SetupNetworkStreams();
                SendBtn.IsEnabled = true;

                // Empfangen der Nachrichten starten
                _cancellationTokenSource = new CancellationTokenSource();
                _ = ReceiveMessagesAsync(_cancellationTokenSource.Token);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Fehler beim Starten des Servers: {ex.Message}");
            }
        }

        private async void ConnectClientBtn_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                string ip = IpTextBox.Text;
                int port = int.Parse(PortTextBox.Text);
                
                _client = new TcpClient();
                // Asynchron verbinden
                await _client.ConnectAsync(ip, port);
                
                StartServerBtn.IsEnabled = false;
                ConnectClientBtn.IsEnabled = false;
                
                AddLogMessage("System", $"Verbunden mit Server {ip}:{port}");

                SetupNetworkStreams();
                SendBtn.IsEnabled = true;

                // Empfangen der Nachrichten starten
                _cancellationTokenSource = new CancellationTokenSource();
                _ = ReceiveMessagesAsync(_cancellationTokenSource.Token);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Fehler beim Verbinden: {ex.Message}");
            }
        }

        private void SetupNetworkStreams()
        {
            var stream = _client!.GetStream();
            _reader = new StreamReader(stream);
            _writer = new StreamWriter(stream) { AutoFlush = true }; // WICHTIG: AutoFlush!
        }

        private async Task ReceiveMessagesAsync(CancellationToken token)
        {
            try
            {
                // Schleife läuft solange die Verbindung aktiv ist und nicht abgebrochen wurde
                while (!token.IsCancellationRequested && _client!.Connected)
                {
                    // Wir lesen immer eine komplette Zeile (ein Json-String = ein Message-Objekt)
                    string? jsonLine = await _reader!.ReadLineAsync();
                    if (string.IsNullOrEmpty(jsonLine))
                    {
                        // Wenn der String leer ist, wurde die Verbindung getrennt
                        break;
                    }

                    // JSON wieder zurück in ein Message-Objekt umwandeln (Deserialisierung)
                    Message? receivedMsg = JsonSerializer.Deserialize<Message>(jsonLine);
                    if (receivedMsg != null)
                    {
                        // Da wir UI-Elemente aktualisieren, müssen wir das über den UI-Thread (Dispatcher) machen
                        Dispatcher.Invoke(() =>
                        {
                            ChatMessages.Add(receivedMsg);
                            ChatListBox.ScrollIntoView(receivedMsg);
                        });
                    }
                }
            }
            catch (Exception)
            {
                // Verbindung wurde getrennt
            }
            finally
            {
                Dispatcher.Invoke(() =>
                {
                    AddLogMessage("System", "Verbindung getrennt.");
                    SendBtn.IsEnabled = false;
                });
            }
        }

        private async void SendBtn_Click(object sender, RoutedEventArgs e)
        {
            if (_writer == null || string.IsNullOrWhiteSpace(MessageTextBox.Text)) return;

            // Message Objekt erstellen
            Message newMessage = new Message
            {
                Sender = NameTextBox.Text,
                Content = MessageTextBox.Text,
                Timestamp = DateTime.Now
            };

            // In der eigenen Liste sofort anzeigen
            ChatMessages.Add(newMessage);
            ChatListBox.ScrollIntoView(newMessage);
            MessageTextBox.Clear();

            try
            {
                // Message-Objekt in einen JSON-String umwandeln (Serialisierung)
                string json = JsonSerializer.Serialize(newMessage);
                
                // Den JSON String über TCP versenden
                await _writer.WriteLineAsync(json);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Fehler beim Senden: {ex.Message}");
            }
        }

        private void AddLogMessage(string sender, string content)
        {
            var msg = new Message { Sender = sender, Content = content, Timestamp = DateTime.Now };
            ChatMessages.Add(msg);
            ChatListBox.ScrollIntoView(msg);
        }

        protected override void OnClosed(EventArgs e)
        {
            // Beim Schließen des Fensters alles ordentlich aufräumen
            _cancellationTokenSource?.Cancel();
            _writer?.Close();
            _reader?.Close();
            _client?.Close();
            _server?.Stop();
            base.OnClosed(e);
        }
    }
}
