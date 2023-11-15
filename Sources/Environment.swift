struct Environment
{
    public mutating func define(name: String, value: Any?)
    {
        self.values[name] = value
    }


    public mutating func assign(name: Token, value: Any?) throws
    {
        if self.values[name.lexeme] == nil
        {
            throw RuntimeError.UndefinedVariable(variable: name)
        }

        self.values[name.lexeme] = value
    }


    public func get(name: Token) throws -> Any?
    {
        guard let value = self.values[name.lexeme] else
        {
            throw RuntimeError.UndefinedVariable(variable: name)
        }
        return value as Any?
    }


    private var values: [String: Any?] = [:]
}