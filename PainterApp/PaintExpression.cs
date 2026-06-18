using Painter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Threading;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace PainterApp
{
    internal class PaintExpression : Expression
    {
        private int  _distance;
        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0)
            {
                if (tokens[0].Type == Token.TokenType.Number)
                {
                    _distance  = int.Parse(tokens[0].Value);
                    tokens.RemoveAt(0);

                }
                else
                {
                    //Fehler
                    Errors.Add("Unexpected Token Type " + tokens[0].Type + ", expected Number");
                }
            }
            else
            {
                //Fehler
                Errors.Add("Unexpected end of PaintExpression, expected Number");
            }
        }

        internal override void Run(PainterControl painter)
        {
            painter.Dispatcher.Invoke(() =>
            {
                painter.Draw(_distance);
            });
        }
    }
}
