using System;
using System.Collections.Generic;
using System.Text;

namespace Gomoku
{
    public interface IGameController
    {
        void MakeMove(Field field);
        bool IsMyTurn { get; set; }
    }

    public class LocalController : IGameController
    {
        public bool IsMyTurn { get; set; } = true;
        public void MakeMove(Field field)
        {
            if (field.State == FieldState.Empty)
            {
                field.State = IsMyTurn ? FieldState.Player1 : FieldState.Player2;
                IsMyTurn = !IsMyTurn; 
            }
        }

        public bool CheckWin(GameBoard board, Field lastMove)
        {
            int[] dx = { 1, 0, 1, 1 }; 
            int[] dy = { 0, 1, 1, -1 };

            for (int i = 0; i < 4; i++)
            {
                int count = 1;
                count += CountInDirection(board, lastMove, dx[i], dy[i]);
                count += CountInDirection(board, lastMove, -dx[i], -dy[i]);
                if (count >= 5) return true;
            }
            return false;
        }

        private int CountInDirection(GameBoard board, Field start, int stepX, int stepY)
        {
            int count = 0;
            int x = start.X + stepX;
            int y = start.Y + stepY;
            while (x >= 0 && x < board.Size && y >= 0 && y < board.Size &&
                   board.Fields.First(f => f.X == x && f.Y == y).State == start.State)
            {
                count++;
                x += stepX;
                y += stepY;
            }
            return count;
        }
    }
}
