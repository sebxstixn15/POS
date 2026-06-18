using Painter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace PainterApp
{
    internal class RotateExpression : Expression
    {
        private int _angle;
        private string _direction;
        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0)
            {
                if (tokens[0].Type == Token.TokenType.String)
                {
                    _direction = tokens[0].Value;
                    tokens.RemoveAt(0);

                }
                else
                {
                    //Fehler
                    Errors.Add("Unexpected Token Type " + tokens[0].Type + ", expected String");
                }
                if (tokens.Count > 0)
                {
                    if (tokens[0].Type == Token.TokenType.Number)
                    {
                        _angle = int.Parse(tokens[0].Value);
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
                    Errors.Add("Unexpected end of RotateExpression, expected Number");
                }
            }
            else
            {
                //Fehler
                Errors.Add("Unexpected end of RotateExpression, expected Number");
            }
        }

        internal override void Run(PainterControl painter)
        {
            painter.Dispatcher.Invoke(() =>
            {
                if (_direction == "LEFT")
                {
                    painter.Rotate(-_angle);
                } else if (_direction == "RIGHT")
                {

                    painter.Rotate(_angle);
                }

            });
        }
    }
}
