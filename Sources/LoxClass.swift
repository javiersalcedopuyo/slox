struct LoxClass: Callable
{
    public func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
    {
        let instance = LoxInstance(class: self)

        if let initializer = self.methods["init"]
        {
            _ = try initializer
                .bind(instance: instance)
                .call(interpreter: interpreter, arguments: arguments)
        }

        return instance
    }


    public func get(static_method name: Token) throws -> Function
    {
        guard let method = self.static_methods[name.lexeme] else
        {
            throw RuntimeError.UndefinedProperty(property: name)
        }

        // Probably not the most efficient...
        let dummy_instance = LoxInstance(class: self)
        return method.bind(instance: dummy_instance)
    }


    let name: String
    var arity: Int
    {
        get
        {
            if let initializer = self.methods["init"]
            {
                return initializer.arity
            }
            return 0
        }
    }

    var methods: [String: Function] = [:]
    var static_methods: [String: Function] = [:]
}
