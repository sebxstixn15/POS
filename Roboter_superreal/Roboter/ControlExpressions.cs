using AbcRobotCore;
using System.Collections.Generic;

namespace Roboter
{
    internal class VarExpression : Expression
    {
        private string _varName;
        private List<Token> _mathTokens = new();

        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Identifier)
            {
                _varName = tokens[0].Value;
                tokens.RemoveAt(0);

                if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Operator && tokens[0].Value == "=")
                {
                    tokens.RemoveAt(0);
                    _mathTokens = MathEvaluator.GatherMathTokens(tokens);
                }
                else
                {
                    Errors.Add("Expected '=' after variable name.");
                }
            }
            else
            {
                Errors.Add("Expected variable name after VAR.");
            }
        }

        internal override void Run(RobotField robot)
        {
            var tempTokens = new List<Token>(_mathTokens);
            double val = MathEvaluator.EvaluateMath(tempTokens);
            Variables[_varName] = val;
        }
    }

    internal class IfExpression : Expression
    {
        private List<Token> _conditionTokens = new();
        private BlockExpression _ifBlock = new();
        private BlockExpression _elseBlock = null;

        internal override void Parse(List<Token> tokens)
        {
            while (tokens.Count > 0 && tokens[0].Type != Token.TokenType.OpenBracket)
            {
                _conditionTokens.Add(tokens[0]);
                tokens.RemoveAt(0);
            }

            _ifBlock.Parse(tokens);

            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Keyword && tokens[0].Value == "ELSE")
            {
                tokens.RemoveAt(0);
                _elseBlock = new BlockExpression();
                _elseBlock.Parse(tokens);
            }
        }

        internal override void Run(RobotField robot)
        {
            var tempTokens = new List<Token>(_conditionTokens);
            bool isTrue = MathEvaluator.EvaluateCondition(tempTokens);

            if (isTrue)
                _ifBlock.Run(robot);
            else if (_elseBlock != null)
                _elseBlock.Run(robot);
        }
    }

    internal class WhileExpression : Expression
    {
        private List<Token> _conditionTokens = new();
        private BlockExpression _block = new();

        internal override void Parse(List<Token> tokens)
        {
            while (tokens.Count > 0 && tokens[0].Type != Token.TokenType.OpenBracket)
            {
                _conditionTokens.Add(tokens[0]);
                tokens.RemoveAt(0);
            }
            _block.Parse(tokens);
        }

        internal override void Run(RobotField robot)
        {
            int safety = 0;
            while (true)
            {
                var tempTokens = new List<Token>(_conditionTokens);
                if (!MathEvaluator.EvaluateCondition(tempTokens)) break;

                _block.Run(robot);
                
                if (++safety > 10000)
                {
                    Errors.Add("While loop infinite loop protection triggered.");
                    break;
                }
            }
        }
    }

    internal class DefExpression : Expression
    {
        private string _funcName;
        private BlockExpression _block = new();

        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Identifier)
            {
                _funcName = tokens[0].Value;
                tokens.RemoveAt(0);
                _block.Parse(tokens);
            }
            else
            {
                Errors.Add("Expected function name after DEF.");
            }
        }

        internal override void Run(RobotField robot)
        {
            Functions[_funcName] = _block;
        }
    }

    internal class CallExpression : Expression
    {
        private string _funcName;

        internal override void Parse(List<Token> tokens)
        {
            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Identifier)
            {
                _funcName = tokens[0].Value;
                tokens.RemoveAt(0);
            }
            else
            {
                Errors.Add("Expected function name after CALL.");
            }
        }

        internal override void Run(RobotField robot)
        {
            if (Functions.ContainsKey(_funcName))
            {
                Functions[_funcName].Run(robot);
            }
            else
            {
                Errors.Add($"Function '{_funcName}' is not defined.");
            }
        }
    }
}
