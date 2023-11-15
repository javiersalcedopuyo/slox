// GRAMMAR: ////////////////////////////////////////////////////////////////////////////////////////
// program      -> statement* EOF ;
// declaration  -> varDecl | statement ;
// varDecl      -> "var" IDENTIFIER ( "=" expression )? ";" ;
// statement    -> exprStmt | printStmt ;
// exprStmt     -> expression ";" ;
// printStmt    -> "print" expression ";" ;
// expression   -> assignment ;
// assignment   -> IDENTIFIER "=" assignment
//                  | ternary ;
// ternary      -> equality ( "?" ternary ":" ternary )?
// equality     -> comparison ( ( "!=" | "==" ) comparision )* ;
// comparison   -> term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term         -> factor ( ( "-" | "+" ) factor )* ;
// factor       -> unary ( ( "/" | "*" ) unary )* ;
// unary        -> ( "!" | "-" ) unary | primary ;
// primary      -> NUMBER | STRING
//                  | "true" | "false" | "nil"
//                  | "(" expression ")"
//                  | IDENTIFIER
//                  // Error productions
//                  | ( "!=" | "==" ) equality
//                  | ( ">" | ">=" | "<" | "<=" ) comparison
//                  | ( "+" ) term
//                  | ( "/" | "*" ) factor ;
////////////////////////////////////////////////////////////////////////////////////////////////////
struct Parser
{
    // - MARK: Public
    public init(tokens t: [Token])
    {
        self.tokens = t
    }


    public mutating func parse() -> [Statement]
    {
        var statements: [Statement] = []
        while !self.is_at_end()
        {
            if let decl = self.declaration()
            {
                statements.append(decl)
            }
        }
        return statements
    }


    // - MARK: Private
    private let tokens: [Token]
    private var current_token_idx = 0


    private mutating func declaration() -> Statement?
    {
        do
        {
            if self.match_and_advance(tokens: .VAR)
            {
                return try self.varDeclaration()
            }
            return try self.statement()
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
        catch ParserError.MissingLeftOperand(let token)
        {
            // TODO: Report the whole expression and highlight the operator
            Lox.error(
                line: token.line,
                message: "Missing left-hand operand of operator `\(token.lexeme)`")
        }
        catch ParserError.InvalidAssignmentTarget(let line)
        {
            Lox.error(line: line, message: "Invalid assignment target.")
            return nil // There's no need to synchronize on this error
        }
        catch
        {
            Lox.error(line: -1, message: "Unkown parsing error.")
        }

        self.sync()
        return nil
    }


    private mutating func varDeclaration() throws -> Statement
    {
        let name = try self.consume(token_type: .IDENTIFIER, message: "Expected variable name.")

        let initializer = self.match_and_advance(tokens: .EQUAL)
            ? try self.expression()
            : nil

        _ = try self.consume(token_type: .SEMICOLON, message: "Expected `;` after declaration.")

        return VarStatement(name: name, initializer: initializer)
    }


    private mutating func statement() throws -> Statement
    {
        if self.match_and_advance(tokens: .PRINT)
        {
            return try self.printStatement()
        }
        return try self.expressionStatement()
    }


    private mutating func printStatement() throws -> Print
    {
        let value = try self.expression()
        try _ = self.consume(token_type: .SEMICOLON, message: "Expected `;` after value.")
        return Print(expression: value)
    }


    private mutating func expressionStatement() throws -> ExpressionStatement
    {
        let expr = try self.expression()
        try _ = self.consume(token_type: .SEMICOLON, message: "Expected `;` after expression.")
        return ExpressionStatement(expression: expr)
    }

    private mutating func expression() throws -> Expression { try self.assignment() }


    private mutating func assignment() throws -> Expression
    {
        let expression = try self.ternary()

        if self.match_and_advance(tokens: .EQUAL)
        {
            guard let expr = expression as? Variable else
            {
                throw ParserError.InvalidAssignmentTarget(line: self.previous().line)
            }
            return Assignment(name: expr.name, value: try self.assignment())
        }

        return expression
    }


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

        if match_and_advance(tokens: .IDENTIFIER)
        {
            return Variable(name: self.previous())
        }

        if match_and_advance(tokens: .LEFT_PARENTHESIS)
        {
            let expression = try expression()

            try _ = self.consume(
                token_type: .RIGHT_PARENTHESIS,
                message: "Expected `)` after expression.")

            return Grouping(expression: expression)
        }

        // Error productions
        if match_and_advance(tokens: .BANG_EQUAL, .EQUAL_EQUAL)
        {
            let token = self.previous()
            try _ = self.equality() // Advance until the end of the expression
            throw ParserError.MissingLeftOperand(token: token)
        }

        if match_and_advance(tokens: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL)
        {
            let token = self.previous()
            try _ = self.comparison() // Advance until the end of the expression
            throw ParserError.MissingLeftOperand(token: token)
        }

        if match_and_advance(tokens: .PLUS)
        {
            let token = self.previous()
            try _ = self.term() // Advance until the end of the expression
            throw ParserError.MissingLeftOperand(token: token)
        }

        if match_and_advance(tokens: .SLASH, .STAR)
        {
            let token = self.previous()
            try _ = self.factor() // Advance until the end of the expression
            throw ParserError.MissingLeftOperand(token: token)
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
    case MissingLeftOperand(token: Token) // TODO: Include the expression for better error message
    case InvalidAssignmentTarget(line: Int)
}