struct LoxClass: Callable
{
    let name: String
    let arity = 0

    public func call(interpreter: inout Interpreter, arguments: [Any?]) throws -> Any?
    {
        return Self(name: self.name)
    }
}
