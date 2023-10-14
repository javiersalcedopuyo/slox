import Foundation

struct Interpreter: Visitor
{
    typealias R = Any?

    // - MARK: Public
	public func visit(_ literalexp: LiteralExp) -> R
    {
        assert( literalexp.value != nil )
        return literalexp.value!
    }


	public func visit(_ grouping: Grouping) -> R { self.evaluate(expression: grouping) }


	public func visit(_ unary: Unary) -> R
    {
        let right = self.evaluate(expression: unary)

        switch unary.op.type
        {
            case .MINUS:
                return -(right as! Double)
            case .BANG:
                return !Self.isTruthful(right)
            default:
                return nil
        }
    }


	public func visit(_ binary: Binary) -> R
    {
        let left  = self.evaluate(expression: binary.left)
        let right = self.evaluate(expression: binary.right)

        switch binary.op.type
        {
            // Comparison
            case .GREATER:
                return (left as! Double) > (right as! Double)
            case .GREATER_EQUAL:
                return (left as! Double) >= (right as! Double)
            case .LESS:
                return (left as! Double) < (right as! Double)
            case .LESS_EQUAL:
                return (left as! Double) <= (right as! Double)

            // Equality
            case .EQUAL_EQUAL:
                return Self.areEqual(left, right)
            case .BANG_EQUAL:
                return !Self.areEqual(left, right)

            // Arithmetic
            case .MINUS:
                return (left as! Double) - (right as! Double)
            case .SLASH:
                return (left as! Double) / (right as! Double)
            case .STAR:
                return (left as! Double) * (right as! Double)
            case .PLUS:
                if
                    let left  = left as? Double,
                    let right = right as? Double
                {
                    return left + right
                }
                else if
                    let left  = left as? String,
                    let right = right as? String
                {
                    return left + right
                }
                else
                {
                    return nil
                }

            default:
                return nil
        }
    }


	public func visit(_ ternary: Ternary) -> R
    {
        let condition = self.evaluate(expression: ternary.condition)
        if Self.isTruthful(condition)
        {
            return self.evaluate(expression: ternary.then_branch)
        }
        else
        {
            return self.evaluate(expression: ternary.else_branch)
        }
    }


    // - MARK: Private
    private func evaluate(expression: Expression) -> R { expression.accept(visitor: self) }


    private static func areEqual(_ a: Any?, _ b: Any?) -> Bool { a as? NSObject == b as? NSObject }


    // Everything that is not `nil` or a false boolean is implicitly converted into TRUE
    private static func isTruthful(_ value: Any?) -> Bool
    {
        guard let value = value else
        {
            return false
        }
        if let boolean = value as? Bool
        {
            return boolean
        }
        return true
    }

}