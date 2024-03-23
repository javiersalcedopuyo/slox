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

    public init(declaration: FunExpression, closure: Environment)
    {
        self.declaration = declaration
        self.arity = declaration.parameters.count
        self.closure = closure
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
            return value
        }
        return nil
    }

    // - MARK: Private
    private let declaration: FunExpression
    private let closure: Environment // The Environment active when the function was *declared*
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
