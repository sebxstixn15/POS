using System;
using System.ComponentModel;
using System.Linq;
using System.Net.Sockets;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;

namespace Gomoku
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private IGameController _currentController;
        private string _statusMessage = "Willkommen bei Gomoku!";

        public GameBoard Board { get; set; }
        public ICommand CellClickCommand { get; }

        public IGameController CurrentController
        {
            get => _currentController;
            set { _currentController = value; OnPropertyChanged(); }
        }

        public string StatusMessage
        {
            get => _statusMessage;
            set { _statusMessage = value; OnPropertyChanged(); }
        }

        public MainViewModel(int size, string mode, TcpClient? networkClient = null, bool isServer = false)
        {
            Board = new GameBoard(size);
            CellClickCommand = new RelayCommand<Field>(ExecuteMove);

            switch (mode)
            {
                case "Mensch":
                    CurrentController = new LocalController();
                    StatusMessage = "Lokales Spiel: Schwarz beginnt.";
                    break;
                case "Computer":
                    CurrentController = new LocalController();
                    StatusMessage = "Computer";
                    break;
                case "Server":
                    CurrentController = new NetworkController(networkClient!, true, Board);
                    StatusMessage = "Server: Du bist Schwarz.";
                    break;
                case "Client":
                    CurrentController = new NetworkController(networkClient!, false, Board);
                    StatusMessage = "Client: Du bist Weiß.";
                    break;
            }
        }

        public void ExecuteMove(Field field)
        {
            if (field.State != FieldState.Empty) return;

            CurrentController.MakeMove(field);

            if (CheckWin(field))
            {
                MessageBox.Show(field.State + " hat gewonnen!");
                return;
            }

            if (StatusMessage == "Computer" && field.State == FieldState.Player1)
            {
                var computerMove = GetComputerMove();
                if (computerMove != null)
                {
                    if (CheckWin(computerMove))
                    {
                        MessageBox.Show("Computer hat gewonnen!");
                        return;
                    }
                    

                    try
                    {
                        CurrentController.IsMyTurn = true;
                    }
                    catch { }
                }
            }
        }

        public bool CheckWin(Field lastMove)
        {
            int[] dx = { 1, 0, 1, 1 }; 
            int[] dy = { 0, 1, 1, -1 };

            for (int i = 0; i < 4; i++)
            {
                int count = 1; 
                count += CountInDirection(lastMove, dx[i], dy[i]);
                count += CountInDirection(lastMove, -dx[i], -dy[i]);

                if (count >= 5) return true;
            }
            return false;
        }

        private int CountInDirection(Field start, int stepX, int stepY)
        {
            int count = 0;
            int x = start.X + stepX;
            int y = start.Y + stepY;

            while (x >= 0 && x < Board.Size && y >= 0 && y < Board.Size)
            {
                var field = Board.Fields.FirstOrDefault(f => f.X == x && f.Y == y);
                if (field != null && field.State == start.State)
                {
                    count++;
                    x += stepX;
                    y += stepY;
                }
                else break;
            }
            return count;
        }

        private Field GetComputerMove()
        {
            var emptyFields = Board.Fields.Where(f => f.State == FieldState.Empty).ToList();
            if (emptyFields.Count == 0) return null;

            foreach (var f in emptyFields)
            {
                f.State = FieldState.Player2;
                if (CheckWin(f)) return f;
                f.State = FieldState.Empty;
            }

            foreach (var f in emptyFields)
            {
                f.State = FieldState.Player1;
                if (CheckWin(f))
                {
                    f.State = FieldState.Player2;
                    return f;
                }
                f.State = FieldState.Empty;
            }

            int center = Board.Size / 2;
            var centerField = Board.Fields.FirstOrDefault(f => f.X == center && f.Y == center && f.State == FieldState.Empty);
            if (centerField != null)
            {
                centerField.State = FieldState.Player2;
                return centerField;
            }

            var rnd = new Random();
            var choice = emptyFields[rnd.Next(emptyFields.Count)];
            choice.State = FieldState.Player2;
            return choice;
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged([CallerMemberName] string? name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}