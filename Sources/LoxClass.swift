class LoxClass: Callable
{
    // - MARK: Public
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


    public func get(method name: String) -> Function?
    {
        guard let method = self.methods[name] else
        {
            return self.superclass?.get(method: name)
        }
        return method
    }

    public func get(static_method name: String) -> Function?
    {
        guard let method = self.static_methods[name] else
        {
            return self.superclass?.get(static_method: name)
        }

        // Probably not the most efficient...
        let dummy_instance = LoxInstance(class: self)
        return method.bind(instance: dummy_instance)
    }


    let name: String
    let superclass: LoxClass?

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


    // - MARK: Private
    private var methods: [String: Function]
    private var static_methods: [String: Function]
}
