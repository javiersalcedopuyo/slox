struct LoxClass: Callable
{
    public func call(interpreter: inout Interpreter, arguments: [Any?]) throws -> Any?
    {
        return LoxInstance(class: self)
    }

    let name: String
    let arity = 0

    var methods: [String: Function] = [:]
}
