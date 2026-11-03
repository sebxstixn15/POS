using Painter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace PainterApp
{
    internal class BlockExpression : Expression
    {
        private Programm _programm = new Programm();
        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0)
            {
                if (tokens[0].Type == Token.TokenType.OpenBracket)
                {
                    tokens.RemoveAt(0);
                    _programm.Parse(tokens);
                    if (tokens.Count > 0)
                    {
                        if (tokens[0].Type == Token.TokenType.CloseBracket)
                        {
                            tokens.RemoveAt(0);
                        }
                        else
                        {
                            //Fehler
                            Errors.Add("Unexpected Token Type" + tokens[0].Type + ", expected Direction");
                        }
                    }
                    else
                    {
                        //Fehler
                        Errors.Add("Unexpected end of BlockExpression, expected }");
                    }
                }
                else
                {
                    //Fehler
                    Errors.Add("Incorrect Block Statement, expecting { and found " + tokens[0].Type + ": " + tokens[0].Value);
                }
            }
            else
            {
                //Fehler
                Errors.Add("Unexpected end of BlockExpression, expected {");
            }
        }

        internal override void Run(PainterControl painter)
        {
            _programm.Run(painter);
        }
    }
}
