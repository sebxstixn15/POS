using System;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Threading.Tasks;

namespace Gomoku
{
    public class NetworkController : IGameController
    {
        private TcpClient _client;
        private StreamWriter _writer;
        private StreamReader _reader;
        private GameBoard _board;
        public bool IsMyTurn { get; set; }

        public NetworkController(TcpClient client, bool isServer, GameBoard board)
        {
            _client = client;
            _board = board;
            var stream = _client.GetStream();
            _writer = new StreamWriter(stream) { AutoFlush = true };
            _reader = new StreamReader(stream);
            IsMyTurn = isServer;

            ListenForOpponent(_board);
        }

        public async void MakeMove(Field field)
        {
            // Nur ziehen, wenn man am Zug ist und das Feld leer ist
            if (IsMyTurn && field.State == FieldState.Empty)
            {
                field.State = FieldState.Player1; // Lokaler Stein (Schwarz für Server, Weiß für Client)
                await _writer.WriteLineAsync($"{field.X},{field.Y}");
                IsMyTurn = false;
            }
        }

        private async void ListenForOpponent(GameBoard board)
        {
            try
            {
                while (true)
                {
                    var line = await _reader.ReadLineAsync();
                    if (line == null) break;

                    var parts = line.Split(',');
                    if (parts.Length == 2 && int.TryParse(parts[0], out int x) && int.TryParse(parts[1], out int y))
                    {
                        System.Windows.Application.Current.Dispatcher.Invoke(() =>
                        {
                            var field = board.Fields.FirstOrDefault(f => f.X == x && f.Y == y);
                            if (field != null)
                            {
                                field.State = FieldState.Player2; // Stein des Gegners
                                IsMyTurn = true;
                            }
                        });
                    }
                }
            }
            catch { /* Verbindung unterbrochen */ }
        }
    }
}