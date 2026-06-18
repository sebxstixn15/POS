using Painter;
using System.Collections.Generic;

namespace PainterApp
{
    internal class RotateExpression : Expression
    {
        private List<Token> _mathTokens = new();
        private string _direction;

        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Identifier)
            {
                _direction = tokens[0].Value;
                tokens.RemoveAt(0);
                
                _mathTokens = MathEvaluator.GatherMathTokens(tokens);
                if (_mathTokens.Count == 0)
                {
                    Errors.Add("Unexpected end of RotateExpression, expected Expression");
                }
            }
            else
            {
                Errors.Add("Unexpected Token Type, expected Direction (Identifier)");
            }
        }

        internal override void Run(PainterControl painter)
        {
            var tempTokens = new List<Token>(_mathTokens);
            double angle = MathEvaluator.EvaluateMath(tempTokens);

            painter.Dispatcher.Invoke(() =>
            {
                if (_direction == "LEFT")
                {
                    painter.Rotate(-(int)angle);
                }
                else if (_direction == "RIGHT")
                {
                    painter.Rotate((int)angle);
                }
            });
        }
    }
}
