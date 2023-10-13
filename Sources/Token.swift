struct Token
{
    func to_string() -> String
    {
        let literal_as_string = self.literal?.to_string() ?? "nil"
        return String(describing: type) + " " +
                lexeme + " " +
                literal_as_string + " " +
                "(ln. " + String(line) + ")"
    }



    let type: TokenType
    let lexeme: String
    let literal: Literal?
    let line: Int
}

enum TokenType
{
    // Single character tokens
    case LEFT_PARENTHESIS
    case RIGHT_PARENTHESIS
    case LEFT_BRACE
    case RIGHT_BRACE
    case COMMA
    case DOT
    case MINUS
    case PLUS
    case COLON
    case SEMICOLON
    case SLASH
    case STAR
    case QUESTION_MARK

    // Comparison tokens
    case BANG
    case BANG_EQUAL
    case EQUAL
    case EQUAL_EQUAL
    case GREATER
    case GREATER_EQUAL
    case LESS
    case LESS_EQUAL

    // Literals
    case IDENTIFIER
    case STRING
    case NUMBER

    // Keywords
    case TRUE
    case FALSE
    case AND
    case OR
    case IF
    case ELSE
    case FOR
    case WHILE
    case CLASS
    case SUPER
    case THIS
    case VAR
    case FUN
    case RETURN
    case NIL
    case PRINT

    case EOF
}

enum Literal
{
    case string(String)
    case identifier(String)
    case number(Double)

    public func to_string() -> String
    {
        switch self
        {
            case .string(let s):        return s
            case .identifier(let s):    return s
            case .number(let n):        return String(n)
        }
    }
}