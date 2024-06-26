class LoxInstance
{
    public init(class c: LoxClass)
    {
        self.lox_class = c
    }

    public func get(_ name: Token) throws -> Any
    {
        // NOTE: Fields shadow methods, and methods shadow static methods!
        if let r = self.fields[name.lexeme]
        {
            return r
        }
        else if let m = self.lox_class.get(method: name.lexeme)
        {
            return m.bind(instance: self)
        }
        else if let m = self.lox_class.get(static_method: name.lexeme)
        {
            return m.bind(instance: self)
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
