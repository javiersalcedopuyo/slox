class Environment
{
    public init()
    {
        self.values = [:]
        self.enclosing_scope = nil
    }


    public init(in_scope environment: Environment)
    {
        self.values = [:]
        self.enclosing_scope = environment
    }


    public func define(name: String, value: Any?)
    {
        self.values[name] = value
    }


    public func assign(name: Token, value: Any?) throws
    {
        if self.values[name.lexeme] == nil
        {
            // See if the variable is defined in an outer scope
            if self.enclosing_scope != nil
            {
                try self.enclosing_scope!.assign(name: name, value: value)
                return
            }
            throw RuntimeError.UndeclaredVariable(variable: name)
        }

        self.values[name.lexeme] = value
    }


    public func get(name: Token) throws -> Any?
    {
        guard let optional_value = self.values[name.lexeme] else
        {
            // See if the variable is declared in an outer scope
            if self.enclosing_scope != nil
            {
                return try self.enclosing_scope!.get(name: name)
            }
            throw RuntimeError.UndeclaredVariable(variable: name)
        }
        guard let value = optional_value else
        {
            // The variable is declared at this scope but left undefined
            throw RuntimeError.UndefinedVariable(variable: name)
        }

        return value
    }


    private var values: [String: Any?]
    private var enclosing_scope: Environment?
}