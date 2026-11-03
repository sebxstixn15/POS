using System;
using System.Net;
using System.Net.Sockets;
using System.Windows;
using System.Windows.Controls;

namespace Gomoku
{
    public partial class StartDialog : Window
    {
        public MainViewModel? ViewModel { get; private set; }
        public StartDialog() => InitializeComponent();

        private async void Start_Click(object sender, RoutedEventArgs e)
        {
            int size = (int)SizeSlider.Value;
            string selectedMode = ModeBox.Text;
            Button? startButton = sender as Button;

            try
            {
                if (selectedMode.Contains("Server"))
                {
                    TcpListener listener = new TcpListener(IPAddress.Any, 8000);
                    listener.Start();

                    if (startButton != null)
                    {
                        startButton.Content = "Warten auf Gegner...";
                        startButton.IsEnabled = false;
                    }

                    // Wartet asynchron auf den Client, ohne die UI zu blockieren
                    var client = await listener.AcceptTcpClientAsync();
                    ViewModel = new MainViewModel(size, "Server", client, true);
                }
                else if (selectedMode.Contains("Client"))
                {
                    TcpClient client = new TcpClient();
                    await client.ConnectAsync("127.0.0.1", 8000);
                    ViewModel = new MainViewModel(size, "Client", client, false);
                }
                else if (selectedMode.Contains("Computer"))
                {
                    ViewModel = new MainViewModel(size, "Computer");
                }
                else
                {
                    ViewModel = new MainViewModel(size, "Mensch");
                }

                // Schließt den Dialog erst, wenn die Verbindung steht oder der Modus bereit ist
                this.DialogResult = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Fehler: " + ex.Message);
                if (startButton != null)
                {
                    startButton.Content = "Spiel starten";
                    startButton.IsEnabled = true;
                }
            }
        }
    }
}