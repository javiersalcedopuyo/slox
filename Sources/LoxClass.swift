class LoxClass: Callable
{
    public init(
        name: String,
        superclass: LoxClass?,
        methods: [String: Function],
        static_methods: [String: Function])
    {
        self.name = name
        self.superclass = superclass
        self.methods = methods
        self.static_methods = static_methods
    }

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
    let superclass: LoxClass?

    var methods: [String: Function]
    var static_methods: [String: Function]

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
}
