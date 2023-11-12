struct Environment
{
    public mutating func define(name: String, value: Any?)
    {
        self.values[name] = value
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