using Painter;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PainterApp
{
    internal class ColorExpression : Expression
    {
        private string _color;
        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0)
            {
                if (tokens[0].Type == Token.TokenType.Identifier)
                {
                    _color = tokens[0].Value;
                    tokens.RemoveAt(0);

                }
                else
                {
                    //Fehler
                    Errors.Add(" Incorrect Color Statement, expecting Colorname and found Keyword: " + tokens[0].Value);
                }
            }
            else
            {
                //Fehler
                Errors.Add("Unexpected end of ColorExpression, expected String");
            }
        }

        internal override void Run(PainterControl painter)
        {
            painter.Dispatcher.Invoke(() =>
            {
                painter.ChangeColor(_color);
            });
        }
    }
}
