using System;
using System.Collections.Generic;
using System.Globalization;

namespace Roboter
{
    internal static class MathEvaluator
    {
        public static List<Token> GatherMathTokens(List<Token> tokens)
        {
            var mathTokens = new List<Token>();
            while (tokens.Count > 0 && (tokens[0].Type == Token.TokenType.Number || tokens[0].Type == Token.TokenType.Identifier || tokens[0].Type == Token.TokenType.Operator))
            {
                mathTokens.Add(tokens[0]);
                tokens.RemoveAt(0);
            }
            return mathTokens;
        }

        public static double EvaluateMath(List<Token> tokens)
        {
            var value = ParseTerm(tokens);
            while (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Operator && (tokens[0].Value == "+" || tokens[0].Value == "-"))
            {
                string op = tokens[0].Value;
                tokens.RemoveAt(0);
                var right = ParseTerm(tokens);
                if (op == "+") value += right;
                else value -= right;
            }
            return value;
        }

        private static double ParseTerm(List<Token> tokens)
        {
            var value = ParseFactor(tokens);
            while (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Operator && (tokens[0].Value == "*" || tokens[0].Value == "/"))
            {
                string op = tokens[0].Value;
                tokens.RemoveAt(0);
                var right = ParseFactor(tokens);
                if (op == "*") value *= right;
                else value = right == 0 ? 0 : value / right;
            }
            return value;
        }

        private static double ParseFactor(List<Token> tokens)
        {
            if (tokens.Count == 0) return 0;
            
            Token token = tokens[0];
            if (token.Type == Token.TokenType.Number)
            {
                tokens.RemoveAt(0);
                return double.Parse(token.Value, CultureInfo.InvariantCulture);
            }
            if (token.Type == Token.TokenType.Identifier)
            {
                tokens.RemoveAt(0);
                if (Expression.Variables.ContainsKey(token.Value))
                    return Expression.Variables[token.Value];
                Expression.Errors.Add($"Variable '{token.Value}' is not defined.");
                return 0;
            }
            
            Expression.Errors.Add($"Expected Number or Variable, found {token.Type}: {token.Value}");
            tokens.RemoveAt(0);
            return 0;
        }

        public static bool EvaluateCondition(List<Token> tokens)
        {
            double left = EvaluateMath(tokens);
            if (tokens.Count > 0 && tokens[0].Type == Token.TokenType.Comparator)
            {
                string op = tokens[0].Value;
                tokens.RemoveAt(0);
                double right = EvaluateMath(tokens);
                return op switch
                {
                    "==" => left == right,
                    "!=" => left != right,
                    "<" => left < right,
                    ">" => left > right,
                    "<=" => left <= right,
                    ">=" => left >= right,
                    _ => false
                };
            }
            Expression.Errors.Add("Expected comparator (==, !=, <, >) in condition.");
            return false;
        }
    }
}
