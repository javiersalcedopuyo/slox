enum ResolverError : Error
{
    case VariableAccessDuringOwnInitialization(var_name: String)
}

struct Resolver: ExpressionVisitor, StatementVisitor
{
    typealias R = Any?
    // - MARK: Public
    public mutating func visit(_ block: Block) throws -> Any?
    {
        self.startScope()
        try self.resolve(statements: block.statements)
        self.endScope()
        return nil
    }

    public mutating func visit(_ varstatement: VarStatement) throws -> Any?
    {
        self.declare(varstatement.name.lexeme)
        if let initializer = varstatement.initializer
        {
            try self.resolve(expression: initializer)
        }
        self.define(varstatement.name.lexeme)
        return nil
    }

    public mutating func visit(_ variable: Variable) throws -> Any?
    {
        if !self.scopes.isEmpty && self.scopes[0][variable.name.lexeme] == false
        {
            throw ResolverError.VariableAccessDuringOwnInitialization(var_name: variable.name.lexeme)
        }
        self.resolve(local_expression: variable, with_name: variable.name.lexeme)
        return nil
    }

    public mutating func visit(_ assignment: Assignment) throws -> Any?
    {
        try self.resolve(expression: assignment.value)
        self.resolve(local_expression: assignment, with_name: assignment.name.lexeme)
        return nil
    }

    public mutating func visit(_ funstatement: FunStatement) throws -> Any?
    {
        self.declare(funstatement.name.lexeme)
        self.define(funstatement.name.lexeme)
        try self.resolve(function: funstatement.function)
        return nil
    }

    public func visit(_ binary: Binary) throws -> Any? { nil }
    public func visit(_ call: Call) throws -> Any? { nil }
    public func visit(_ grouping: Grouping) throws -> Any? { nil }
    public func visit(_ literalexp: LiteralExp) throws -> Any? { nil    }
    public func visit(_ logical: Logical) throws -> Any? { nil }
    public func visit(_ unary: Unary) throws -> Any? { nil }
    public func visit(_ ternary: Ternary) throws -> Any? { nil }
    public func visit(_ funexpression: FunExpression) throws -> Any? { nil }
    public func visit(_ expressionstatement: ExpressionStatement) throws -> Any? { nil }
    public func visit(_ conditionalstatement: ConditionalStatement) throws -> Any? { nil }
    public func visit(_ whilestatement: WhileStatement) throws -> Any? { nil }
    public func visit(_ breakstatement: BreakStatement) throws -> Any? { nil }
    public func visit(_ print: Print) throws -> Any? { nil }
    public func visit(_ returnstatment: ReturnStatment) throws -> Any? { nil }

    // - MARK: Private
    private mutating func startScope()
    {
        self.scopes.insert([:], at: 0)
    }

    private mutating func endScope()
    {
        assert( !self.scopes.isEmpty )
        self.scopes.removeFirst()
    }

    private mutating func declare(_ name: String)
    {
        if self.scopes.isEmpty
        {
            return
        }
        self.scopes[0][name] = false // We're not ready yet
    }

    private mutating func define(_ name: String)
    {
        if self.scopes.isEmpty
        {
            return
        }
        self.scopes[0][name] = true // Done initializing
    }

    private mutating func resolve(statements: [Statement]) throws
    {
        for s in statements
        {
            try self.resolve(statement: s)
        }
    }

    private mutating func resolve(statement: Statement) throws
    {
        _ = try statement.accept(visitor: &self)
    }

    private mutating func resolve(expression: Expression) throws
    {
        _ = try expression.accept(visitor: &self)
    }

    private mutating func resolve(local_expression: Expression, with_name name: String)
    {
        for (i, scope) in self.scopes.enumerated()
        {
            if scope[name] != nil
            {
                _ = i
                // TODO: self.interpreter.resolve(expression: local_expression, hops: i)
            }
        }
    }

    private mutating func resolve(function: FunExpression) throws
    {
        self.startScope()
        defer{ self.endScope() }

        for parameter in function.parameters
        {
            self.declare(parameter.lexeme)
            self.define(parameter.lexeme)
        }
        try self.resolve(statements: function.body.statements)
    }

    // NOTE: Only for block scopes. Global scope is not tracked.
    // TODO: This is meant to be a STACK of Dictionaries. Make an actual Stack type
    private var scopes: [[String: Bool]] = [[:]] // Name -> Have we finished resolving its initializer?
}