// GRAMMAR: ////////////////////////////////////////////////////////////////////////////////////////
// program      -> statement* EOF ;
// declaration  -> varDecl | statement ;
// varDecl      -> "var" IDENTIFIER ( "=" expression )? ";" ;
// whileStmt    -> "while" "("expression")" statement;
// forStmt      -> "for" "("
//                      (varDecl | exprStmt) ";"
//                      expression? ";"
//                      expression? ")"
//                  statement;
// statement    -> exprStmt | printStmt | ifStmt | block;
// block        -> "{" declaration "}"
// exprStmt     -> expression ";" ;
// printStmt    -> "print" expression ";" ;
// ifStmt       -> "if" "(" expression ")" statement ( "else" statement )?;
// expression   -> assignment ;
// assignment   -> IDENTIFIER "=" assignment
//                  | ternary ;
// ternary      -> logic_or ( "?" ternary ":" ternary )?
// logic_or     -> logic_and ( "or" logic_and)*;
// logic_and    -> equality ( "and" equality)*;
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
    private var loop_indent_level = 0


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
        catch ParserError.BreakStatementOutsideLoop(let line)
        {
            Lox.error(line: line, message: "Break statement used outside of loop.")
        }
        catch ParserError.ContinueStatementOutsideLoop(let line)
        {
            Lox.error(line: line, message: "Continue statement used outside of loop.")
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
        if self.match_and_advance(tokens: .LEFT_BRACE)
        {
            return Block(statements: try self.blockStatement())
        }
        if self.match_and_advance(tokens: .IF)
        {
            return try self.conditionalStatement()
        }
        if self.match_and_advance(tokens: .WHILE)
        {
            return try self.whileStatement()
        }
        if self.match_and_advance(tokens: .FOR)
        {
            return try self.forStatement()
        }
        if self.match_and_advance(tokens: .BREAK)
        {
            return try self.breakStatement()
        }
        if self.match_and_advance(tokens: .CONTINUE)
        {
            // TODO:
        }
        return try self.expressionStatement()
    }


    private mutating func printStatement() throws -> Print
    {
        let value = try self.expression()
        try _ = self.consume(token_type: .SEMICOLON, message: "Expected `;` after value.")
        return Print(expression: value)
    }


    private mutating func blockStatement() throws -> [Statement]
    {
        var statements: [Statement] = []

        while !self.check_current_token(of_type: .RIGHT_BRACE) && !self.is_at_end()
        {
            if let decl = self.declaration()
            {
                statements.append(decl)
            }
        }
        try _ = self.consume(token_type: .RIGHT_BRACE, message: "Expected `}` after block.")
        return statements
    }


    private mutating func conditionalStatement() throws -> Statement
    {
        try _ = self.consume(token_type: .LEFT_PARENTHESIS, message: "Expected `(` after if.")
        let condition = try self.expression()
        try _ = self.consume(token_type: .RIGHT_PARENTHESIS, message: "Expected `)` after if condition.")
        let then_branch = try self.statement()

        var else_branch: Statement? = nil
        if self.match_and_advance(tokens: .ELSE)
        {
            else_branch = try self.statement()
        }

        return ConditionalStatement(
            condition: condition,
            then_branch: then_branch,
            else_branch: else_branch)
    }


    private mutating func whileStatement() throws -> Statement
    {
        self.loop_indent_level += 1
        defer { self.loop_indent_level -= 1 }

        _ = try self.consume(token_type: .LEFT_PARENTHESIS, message: "Expected `(` after `while`.")
        let condition = try self.expression()
        _ = try self.consume(token_type: .RIGHT_PARENTHESIS, message: "Expected `)` after `while` condition.")
        let body = try self.statement()

        return WhileStatement(condition: condition, body: body)
    }


    private mutating func forStatement() throws -> Statement
    {
        self.loop_indent_level += 1
        defer { self.loop_indent_level -= 1 }

        _ = try self.consume(token_type: .LEFT_PARENTHESIS, message: "Expected `(` after `for`.")
        var initializer: Statement?
        if self.match_and_advance(tokens: .SEMICOLON)
        {
            initializer = nil
        }
        else if self.match_and_advance(tokens: .VAR)
        {
            initializer = try self.varDeclaration()
        }
        else
        {
            initializer = try self.expressionStatement()
        }

        let condition = self.check_current_token(of_type: .SEMICOLON)
            ? LiteralExp(value: .keyword("true"))
            : try self.expression()
        _ = try self.consume(token_type: .SEMICOLON, message: "Expected `;` after loop condition.")

        var increment: Expression? = nil
        if !self.check_current_token(of_type: .RIGHT_PARENTHESIS)
        {
            increment = try self.expression()
        }
        _ = try self.consume(token_type: .RIGHT_PARENTHESIS, message: "Expected `)` after for clauses.")

        var body = try self.statement()

        // Apply the increment expression after each iteration of the body
        if let increment = increment
        {
            body = Block(
                statements: [
                    body,
                    ExpressionStatement(expression: increment) ])
        }

        // Execute the body while the condition is true
        body = WhileStatement(condition: condition, body: body)

        // Run the initializer before anything else in the loop
        if let initializer = initializer
        {
            body = Block(statements: [initializer, body])
        }

        return body
    }


    private mutating func breakStatement() throws -> Statement
    {
        if self.loop_indent_level == 0
        {
            throw ParserError.BreakStatementOutsideLoop(line: self.previous().line)
        }
        _ = try self.consume(token_type: .SEMICOLON, message: "Expected `;` after expression.")
        return BreakStatement()
    }


    // TODO: private mutating func continueStatement() throws -> Statement


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
        var expression = try self.or_operator()
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


    private mutating func or_operator() throws -> Expression
    {
        var expression = try self.and_operator()

        while self.match_and_advance(tokens: .OR)
        {
            let op = self.previous()
            let right = try self.and_operator()
            expression = Logical(left: expression, op: op, right: right)
        }
        return expression
    }


    private mutating func and_operator() throws -> Expression
    {
        var expression = try self.equality()
        while self.match_and_advance(tokens: .AND)
        {
            let op = self.previous()
            let right = try self.equality()
            expression = Logical(left: expression, op: op, right: right)
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
        if match_and_advance(tokens: .FALSE)    { return LiteralExp(value: .keyword("false")) }
        if match_and_advance(tokens: .TRUE)     { return LiteralExp(value: .keyword("true")) }
        if match_and_advance(tokens: .NIL)      { return LiteralExp(value: .keyword("nil")) }

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
    case BreakStatementOutsideLoop(line: Int)
    case ContinueStatementOutsideLoop(line: Int)
}