enum ResolverError : Error
{
    case VariableAccessDuringOwnInitialization(var_name: String)
}

struct Resolver: ExpressionVisitor, StatementVisitor
{
    typealias R = Any?
    // - MARK: Public
    public init(interpreter i: Interpreter) { self.interpreter = i }


    public mutating func resolve(statements: [Statement]) throws
    {
        for s in statements
        {
            try self.resolve(statement: s)
        }
    }


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
        try self.resolve(local_expression: variable, with_name: variable.name.lexeme)
        return nil
    }

    public mutating func visit(_ assignment: Assignment) throws -> Any?
    {
        try self.resolve(expression: assignment.value)
        try self.resolve(local_expression: assignment, with_name: assignment.name.lexeme)
        return nil
    }

    public mutating func visit(_ funstatement: FunStatement) throws -> Any?
    {
        self.declare(funstatement.name.lexeme)
        self.define(funstatement.name.lexeme)
        try self.resolve(function: funstatement.function)
        return nil
    }

    mutating public func visit(_ expressionstatement: ExpressionStatement) throws -> Any?
    {
        try self.resolve(expression: expressionstatement.expression)
        return nil
    }

    mutating public func visit(_ conditionalstatement: ConditionalStatement) throws -> Any?
    {
        try self.resolve(expression: conditionalstatement.condition)
        try self.resolve(statement: conditionalstatement.then_branch)
        if let else_branch = conditionalstatement.else_branch
        {
            try self.resolve(statement:else_branch)
        }
        return nil
    }

    mutating public func visit(_ print: Print) throws -> Any?
    {
        try self.resolve(expression: print.expression)
        return nil
    }

    mutating public func visit(_ returnstatment: ReturnStatment) throws -> Any?
    {
        if let e = returnstatment.value
        {
            try self.resolve(expression: e)
        }
        return nil
    }

    mutating public func visit(_ whilestatement: WhileStatement) throws -> Any?
    {
        try self.resolve(expression: whilestatement.condition)
        try self.resolve(statement: whilestatement.body)
        return nil
    }


    mutating public func visit(_ binary: Binary) throws -> Any?
    {
        try self.resolve(expression: binary.left)
        try self.resolve(expression: binary.right)
        return nil
    }

    mutating public func visit(_ call: Call) throws -> Any?
    {
        try self.resolve(expression: call.callee)
        for e in call.arguments
        {
            try self.resolve(expression: e)
        }
        return nil
    }

    mutating public func visit(_ grouping: Grouping) throws -> Any?
    {
        try self.resolve(expression: grouping.expression)
        return nil
    }

    mutating public func visit(_ logical: Logical) throws -> Any?
    {
        try self.resolve(expression: logical.left)
        try self.resolve(expression: logical.right)
        return nil
    }

    mutating public func visit(_ unary: Unary) throws -> Any?
    {
        try self.resolve(expression: unary.right)
        return nil
    }

    mutating public func visit(_ ternary: Ternary) throws -> Any?
    {
        try self.resolve(expression: ternary.condition)
        try self.resolve(expression: ternary.then_branch)
        try self.resolve(expression: ternary.else_branch)
        return nil
    }

    mutating public func visit(_ literalexp: LiteralExp) throws -> Any? { nil }
    mutating public func visit(_ funexpression: FunExpression) throws -> Any? { nil }
    mutating public func visit(_ breakstatement: BreakStatement) throws -> Any? { nil }

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

    private mutating func resolve(statement: Statement) throws
    {
        _ = try statement.accept(visitor: &self)
    }

    private mutating func resolve(expression: Expression) throws
    {
        _ = try expression.accept(visitor: &self)
    }

    private mutating func resolve(local_expression: Expression, with_name name: String) throws
    {
        for (i, scope) in self.scopes.enumerated()
        {
            if scope[name] != nil
            {
                try self.interpreter.resolve(expression: local_expression, depth: i)
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
    private var interpreter: Interpreter
}