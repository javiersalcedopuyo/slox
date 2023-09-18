// GRAMMAR: ////////////////////////////////////////////////////////////////////////////////////////
// expression   -> equality ;
// equality     -> comparison ( ( "!=" | "==" ) comparision )* ;
// comparison   -> term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term         -> factor ( ( "-" | "+" ) factor )* ;
// factor       -> unary ( ( "/" | "*" ) unary )* ;
// unary        -> ( "!" | "-" ) unary | primary ;
// primary      -> NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")" ;
////////////////////////////////////////////////////////////////////////////////////////////////////
struct Parser
{
    private let tokens: [Token]
    private var current_token_idx = 0


    private mutating func expression() -> Expression { self.equality() }


    private mutating func equality() -> Expression
    {
        var expression = self.comparison()
        while match_and_advance(tokens: .BANG_EQUAL, .EQUAL_EQUAL)
        {
            expression = Binary(
                left: expression,
                op: self.previous(),
                right: comparison() )
        }
        return expression
    }


    private mutating func comparison() -> Expression
    {
        var expression = term()
        while match_and_advance(tokens:
            .GREATER,
            .GREATER_EQUAL,
            .LESS,
            .LESS_EQUAL)
        {
            expression = Binary(
                left: expression,
                op: previous(),
                right: term())
        }
        return expression
    }


    private mutating func term() -> Expression
    {
        var expression = factor()
        while match_and_advance(tokens: .MINUS, .PLUS)
        {
            expression = Binary(
                left: expression,
                op: previous(),
                right: factor())
        }
        return expression
    }


    private mutating func factor() -> Expression
    {
        var expression = unary()
        while match_and_advance(tokens: .SLASH, .STAR)
        {
            expression = Binary(
                left: expression,
                op: previous(),
                right: unary())
        }
        return expression
    }


    private mutating func unary() -> Expression
    {
        if match_and_advance(tokens: .BANG, .MINUS)
        {
            return Unary(op: previous(), right: unary())
        }
        return primary()
    }


    private mutating func primary() -> Expression
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
            let expression = expression()
            assert(self.peek().type == .RIGHT_PARENTHESIS)
            return Grouping(expression: expression)
        }

        fatalError("Invalid token \(self.peek().to_string())")
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
}