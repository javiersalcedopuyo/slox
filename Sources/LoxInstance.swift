class LoxInstance
{
    public init(class c: LoxClass)
    {
        self.lox_class = c
    }

    public func get(_ name: Token) throws -> Any
    {
        // NOTE: Fields shadow methods!
        if let r = self.fields[name.lexeme]
        {
            return r
        }
        else if let m = self.lox_class.methods[name.lexeme]
        {
            return m
        }
        throw RuntimeError.UndefinedProperty(property: name)
    }

    public func set(property: Token, value: Any?)
    {
        self.fields[property.lexeme] = value
    }

    public func get_type_name() -> String { self.lox_class.name }

    private let lox_class: LoxClass
    private var fields: [String: Any] = [:]
}
