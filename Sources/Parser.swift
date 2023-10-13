// GRAMMAR: ////////////////////////////////////////////////////////////////////////////////////////
// expression   -> ternary ;
// ternary      -> equality ( "?" ternary ":" ternary )
// equality     -> comparison ( ( "!=" | "==" ) comparision )* ;
// comparison   -> term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term         -> factor ( ( "-" | "+" ) factor )* ;
// factor       -> unary ( ( "/" | "*" ) unary )* ;
// unary        -> ( "!" | "-" ) unary | primary ;
// primary      -> NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")" ;
////////////////////////////////////////////////////////////////////////////////////////////////////
struct Parser
{
    // - MARK: Public
    public init(tokens t: [Token])
    {
        self.tokens = t
    }


    public mutating func parse() -> Expression?
    {
        do
        {
            return try self.expression()
        }
        catch ParserError.ExpectedExpression(let token)
        {
            Lox.error(
                line: token.line,
                message: "Expected expression, found \(token.to_string())")
        }
        catch ParserError.InvalidToken(let token, let message)
        {
            Lox.error(line: token.line, message: message)
        }
        catch
        {
            Lox.error(line: -1, message: "Unkown parsing error.")
        }

        return nil
    }


    // - MARK: Private
    private let tokens: [Token]
    private var current_token_idx = 0


    private mutating func expression() throws -> Expression { try self.ternary() }


    private mutating func ternary() throws -> Expression
    {
        var expression = try self.equality()
        if match_and_advance(tokens: .QUESTION_MARK )
        {
            let then_branch = try self.ternary()
            try _ = self.consume(token_type: .COLON, message: "Expected `:` in  ternary operator.")
            let else_branch = try self.ternary()

            expression = Ternary(
                condition: expression,
                then_branch: then_branch,
                else_branch: else_branch)
        }
        return expression
    }


    private mutating func equality() throws -> Expression
    {
        var expression = try self.comparison()
        while match_and_advance(tokens: .BANG_EQUAL, .EQUAL_EQUAL)
        {
            try expression = Binary(
                left: expression,
                op: self.previous(),
                right: comparison() )
        }
        return expression
    }


    private mutating func comparison() throws -> Expression
    {
        var expression = try term()
        while match_and_advance(tokens:
            .GREATER,
            .GREATER_EQUAL,
            .LESS,
            .LESS_EQUAL)
        {
            try expression = Binary(
                left: expression,
                op: previous(),
                right: term())
        }
        return expression
    }


    private mutating func term() throws -> Expression
    {
        var expression = try factor()
        while match_and_advance(tokens: .MINUS, .PLUS)
        {
            try expression = Binary(
                left: expression,
                op: previous(),
                right: factor())
        }
        return expression
    }


    private mutating func factor() throws -> Expression
    {
        var expression = try unary()
        while match_and_advance(tokens: .SLASH, .STAR)
        {
            try expression = Binary(
                left: expression,
                op: previous(),
                right: unary())
        }
        return expression
    }


    private mutating func unary() throws -> Expression
    {
        if match_and_advance(tokens: .BANG, .MINUS)
        {
            return try Unary(op: previous(), right: unary())
        }
        return try primary()
    }


    private mutating func primary() throws -> Expression
    {
        if match_and_advance(tokens: .FALSE)    { return LiteralExp(value: .string("false")) }
        if match_and_advance(tokens: .TRUE)     { return LiteralExp(value: .string("true")) }
        if match_and_advance(tokens: .NIL)      { return LiteralExp(value: .string("nil")) }

        if match_and_advance(tokens: .NUMBER, .STRING)
        {
            return LiteralExp(value: self.previous().literal )
        }

        if match_and_advance(tokens: .LEFT_PARENTHESIS)
        {
            let expression = try expression()

            try _ = self.consume(
                token_type: .RIGHT_PARENTHESIS,
                message: "Expected `)` after expression.")

            return Grouping(expression: expression)
        }

        throw ParserError.ExpectedExpression(token: self.peek())
    }


    // - MARK: Utiliy functions
    private mutating func match_and_advance(tokens: TokenType...) -> Bool
    {
        for type in tokens
        {
            if self.check_current_token(of_type: type)
            {
                _ = self.advance()
                return true
            }
        }
        return false
    }


    private func check_current_token(of_type type: TokenType) -> Bool
    {
        self.is_at_end() == false && self.peek().type == type
    }


    private func peek() -> Token
    {
        assert(self.current_token_idx < self.tokens.count)
        return self.tokens[self.current_token_idx]
    }


    private func is_at_end() -> Bool
    {
        self.current_token_idx >= self.tokens.count
        || self.peek().type == .EOF
    }


    private mutating func advance() -> Token
    {
        let token = self.peek()
        if self.is_at_end() == false
        {
            self.current_token_idx += 1
        }
        return token
    }


    // TODO: Make it return an optional?
    private func previous() -> Token
    {
        assert(self.current_token_idx > 0)
        return self.tokens[self.current_token_idx - 1]
    }


    private mutating func consume(
        token_type: TokenType,
        message: String)
    throws
    -> Token
    {
        if self.check_current_token(of_type: token_type)
        {
            return self.advance()
        }

        throw ParserError.InvalidToken(
            token: self.peek(),
            message: message)
    }


    /// Advances until the start of the next statement, discarding the tokens in the process.
    /// This is only meant to be called after encountering an error.
    private mutating func sync()
    {
        _ = self.advance()
        while self.is_at_end() == false
        {
            // If the previous token was a semicolon we're already at the start of the next statement
            if self.previous().type == .SEMICOLON
            {
                return
            }

            switch self.peek().type
            {
                // If the current token is one of these, it's the start of a statement
                case
                .CLASS,
                .FOR,
                .FUN,
                .IF,
                .PRINT,
                .RETURN,
                .VAR,
                .WHILE:
                    return

                // Otherwise continue
                default: _ = self.advance()
            }
        }
    }
}


enum ParserError : Error
{
    case InvalidToken(token: Token, message: String)
    case ExpectedExpression(token: Token)
}