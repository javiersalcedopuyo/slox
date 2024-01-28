import Foundation


protocol Callable
{
    var arity: Int {get}
    func call(interpreter: Interpreter, arguments: [Any?]) -> Any?
}


// - MARK: Primitive/foreign functions

/// Primitive that returns the time in seconds since 00:00:00 UTC on 1 January 1970.
struct ClockPrimitive: Callable
{
    let arity = 0

    public func call(interpreter: Interpreter, arguments: [Any?]) -> Any?
    {
        return NSDate().timeIntervalSince1970
    }
}