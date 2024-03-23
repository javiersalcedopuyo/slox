struct LoxClass: Callable
{
    public func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
    {
        return LoxInstance(class: self)
    }

    let name: String
    let arity = 0

    var methods: [String: Function] = [:]
}
