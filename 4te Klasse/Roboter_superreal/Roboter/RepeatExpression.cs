using AbcRobotCore;
using System.Collections.Generic;

namespace Roboter
{
    internal class RepeatExpression : Expression
    {
        private List<Token> _mathTokens = new();
        private Expression _block = new BlockExpression();

        internal override void Parse(List<Token> tokens)
        {
            _mathTokens = MathEvaluator.GatherMathTokens(tokens);
            if (_mathTokens.Count > 0)
            {
                _block.Parse(tokens);
            }
            else
            {
                Errors.Add("Unexpected end of RepeatExpression, expected Expression");
            }
        }

        internal override void Run(RobotField robot)
        {
            var tempTokens = new List<Token>(_mathTokens);
            int count = (int)MathEvaluator.EvaluateMath(tempTokens);

            for (int i = 0; i < count; i++)
            {
                _block.Run(robot);
            }
        }
    }
}