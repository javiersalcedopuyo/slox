// NOTE: We don't really throw errors because we want to continue resolving
// and report all errors at once.
// enum ResolverError : Error
// {
//     case VariableAccessDuringOwnInitialization(var_token: Token)
//     case VariableRedefinition(var_token: Token)
//     case ReturnFromOutsideFunction
// }

class Resolver: ExpressionVisitor, StatementVisitor
{
    typealias R = Any?
    // - MARK: Public
    public init(interpreter i: Interpreter) { self.interpreter = i }


    public func resolve(statements: [Statement]) throws
    {
        for s in statements
        {
            try self.resolve(statement: s)
        }
    }


    public func visit(_ block: Block) throws -> Any?
    {
        self.startScope()
        try self.resolve(statements: block.statements)
        self.endScope()
        return nil
    }

    public func visit(_ varstatement: VarStatement) throws -> Any?
    {
        self.declare(varstatement.name)
        if let initializer = varstatement.initializer
        {
            try self.resolve(expression: initializer)
        }
        self.define(varstatement.name.lexeme)
        return nil
    }

    public func visit(_ variable: Variable) throws -> Any?
    {
        if !self.scopes.isEmpty
            && self.scopes[0][variable.name.lexeme] != nil
            && self.scopes[0][variable.name.lexeme]!.status == .Declared
        {
            Lox.error(
                line:variable.name.line,
                message: "Resolver error: Variable \(variable.name.lexeme) accessed during its own initialization.")
        }

        self.resolve(local_expression: variable, with_name: variable.name.lexeme)
        return nil
    }

    public func visit(_ assignment: Assignment) throws -> Any?
    {
        try self.resolve(expression: assignment.value)
        self.resolve(local_expression: assignment, with_name: assignment.name.lexeme)
        return nil
    }

    public func visit(_ classdeclaration: ClassDeclaration) throws -> Any?
    {
        self.declare(classdeclaration.name)
        self.define(classdeclaration.name.lexeme)

        for method in classdeclaration.methods
        {
            assert(method.function.type == .Method);
            try self.resolve(function: method.function)
        }

        return nil
    }

    public func visit(_ funstatement: FunStatement) throws -> Any?
    {
        self.declare(funstatement.name)
        self.define(funstatement.name.lexeme)
        try self.resolve(function: funstatement.function)
        return nil
    }

    public func visit(_ expressionstatement: ExpressionStatement) throws -> Any?
    {
        try self.resolve(expression: expressionstatement.expression)
        return nil
    }

    public func visit(_ conditionalstatement: ConditionalStatement) throws -> Any?
    {
        try self.resolve(expression: conditionalstatement.condition)
        try self.resolve(statement: conditionalstatement.then_branch)
        if let else_branch = conditionalstatement.else_branch
        {
            try self.resolve(statement:else_branch)
        }
        return nil
    }

    public func visit(_ print: Print) throws -> Any?
    {
        try self.resolve(expression: print.expression)
        return nil
    }

    public func visit(_ returnstatment: ReturnStatment) throws -> Any?
    {
        if self.current_function == nil
        {
            // TODO: Report the line
            Lox.error(line: -1, message: "Resolver error: Return statement outside of function.")
        }

        if let e = returnstatment.value
        {
            try self.resolve(expression: e)
        }
        return nil
    }

    public func visit(_ whilestatement: WhileStatement) throws -> Any?
    {
        try self.resolve(expression: whilestatement.condition)
        try self.resolve(statement: whilestatement.body)
        return nil
    }


    public func visit(_ binary: Binary) throws -> Any?
    {
        try self.resolve(expression: binary.left)
        try self.resolve(expression: binary.right)
        return nil
    }

    public func visit(_ call: Call) throws -> Any?
    {
        try self.resolve(expression: call.callee)
        for e in call.arguments
        {
            try self.resolve(expression: e)
        }
        return nil
    }

    public func visit(_ getter: Getter) throws -> Any?
    {
        try self.resolve(expression: getter.obj)
        // NOTE: Because properties are looked up dynamically, they don't get resolved
        return nil
    }

    public func visit(_ setter: Setter) throws -> Any?
    {
        try self.resolve(expression: setter.value)
        try self.resolve(expression: setter.obj)
        return nil
    }

    public func visit(_ grouping: Grouping) throws -> Any?
    {
        try self.resolve(expression: grouping.expression)
        return nil
    }

    public func visit(_ logical: Logical) throws -> Any?
    {
        try self.resolve(expression: logical.left)
        try self.resolve(expression: logical.right)
        return nil
    }

    public func visit(_ unary: Unary) throws -> Any?
    {
        try self.resolve(expression: unary.right)
        return nil
    }

    public func visit(_ ternary: Ternary) throws -> Any?
    {
        try self.resolve(expression: ternary.condition)
        try self.resolve(expression: ternary.then_branch)
        try self.resolve(expression: ternary.else_branch)
        return nil
    }

    public func visit(_ literalexp: LiteralExp) throws -> Any? { nil }
    public func visit(_ funexpression: FunExpression) throws -> Any? { nil }
    public func visit(_ breakstatement: BreakStatement) throws -> Any? { nil }

    // - MARK: Private
    private func startScope()
    {
        self.scopes.insert([:], at: 0)
    }

    private func endScope()
    {
        assert( !self.scopes.isEmpty )
        for entry in self.scopes[0]
        {
            if entry.value.status != .Read
            {
                Lox.error(
                    line: entry.value.name.line,
                    message: "Resolver error: Local variable \(entry.value.name.lexeme) unused." )
            }
        }
        self.scopes.removeFirst()
    }

    private func declare(_ name: Token)
    {
        if self.scopes.isEmpty
        {
            return
        }
        if self.scopes[0][name.lexeme] != nil
        {
            // TODO: Report where it was defined?
            Lox.error(
                line: name.line,
                message: "Resolver error: Variable \(name.lexeme) is already defined in this scope.")
        }
        self.scopes[0][name.lexeme] = ResolvedVariable( name: name, status: .Declared )
    }

    private func define(_ name: String)
    {
        if self.scopes.isEmpty
        {
            return
        }
        // Defining an undeclared variable should not be possible
        assert( self.scopes[0][name] != nil )

        self.scopes[0][name]!.status = .Defined
    }

    private func resolve(statement: Statement) throws
    {
        _ = try statement.accept(visitor: self)
    }

    private func resolve(expression: Expression) throws
    {
        _ = try expression.accept(visitor: self)
    }

    private func resolve(local_expression: Expression, with_name name: String)
    {
        for (i, scope) in self.scopes.enumerated()
        {
            if scope[name] != nil
            {
                self.scopes[i][name]!.status = .Read
                self.interpreter.resolve(expression: local_expression, depth: i)
            }
        }
    }

    private func resolve(function: FunExpression) throws
    {
        let enclosing_function = self.current_function
        defer{ self.current_function = enclosing_function }

        self.current_function = function.type

        self.startScope()
        defer{ self.endScope() }

        for parameter in function.parameters
        {
            self.declare(parameter)
            self.define(parameter.lexeme)
        }
        try self.resolve(statements: function.body.statements)
    }

    // NOTE: Only for block scopes. Global scope is not tracked.
    // TODO: This is meant to be a STACK of Dictionaries. Make an actual Stack type
    private var scopes: [[String: ResolvedVariable]] = [[:]] // Name -> Have we finished resolving its initializer?
    private var interpreter: Interpreter
    private var current_function: FunctionType? = nil

    private struct ResolvedVariable
    {
        let name: Token
        var status: Status

        public enum Status: UInt8
        {
            case Declared = 0
            case Defined = 1
            case Read = 2
        }
    }
}
