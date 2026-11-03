using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Roboter
{
    internal class Token
    {
        public enum TokenType { Keyword, Identifier, String, Number, Direction, Operator, Comparator, OpenBracket, CloseBracket, Error }
        public string Value { get; set; }
        public TokenType Type { get; set; } = TokenType.Error;

    }
}
