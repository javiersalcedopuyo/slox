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
}
