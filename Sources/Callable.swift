import Foundation


protocol Callable
{
    var arity: Int {get}
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
}


struct Function: Callable
{
    // - MARK: Public
    public let arity: Int;

    public init(declaration: FunExpression, closure: Environment, is_initializer: Bool)
    {
        self.declaration = declaration
        self.arity = declaration.parameters.count
        self.closure = closure
        self.is_initializer = is_initializer
    }

    public func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
    {
        assert( self.declaration.parameters.count == arguments.count )

        let environment = Environment(in_scope: self.closure)

        var i = 0
        for parameter in self.declaration.parameters
        {
            environment.define(name: parameter.lexeme, value: arguments[i])
            i += 1
        }

        do
        {
            try interpreter.execute(block: self.declaration.body, environment: environment)
        }
        catch FlowBreakers.Return(let value)
        {
            if self.is_initializer
            {
                // An initializer always returns `nil` but we want it to return `this`.
                // Crash if we can't find `this` in an initializer. Something has gone very wrong.
                return try! self.closure.get(at_distance: 0, name: "this")
            }
            return value
        }
        return nil
    }


    public func bind(instance: LoxInstance) -> Function
    {
        let environment = Environment(in_scope: self.closure)
        environment.define(name: "this", value: instance)

        return Function(
            declaration: self.declaration,
            closure: environment,
            is_initializer: self.is_initializer)
    }


    public func isGetter() -> Bool { self.declaration.type == .Getter }


    // - MARK: Private
    private let declaration: FunExpression
    private let closure: Environment // The Environment active when the function was *declared*
    private let is_initializer: Bool
}


// - MARK: Primitive/foreign functions

/// Primitive that returns the time in seconds since 00:00:00 UTC on 1 January 1970.
struct ClockPrimitive: Callable
{
    let arity = 0

    public func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any?
    {
        return NSDate().timeIntervalSince1970
    }
}
