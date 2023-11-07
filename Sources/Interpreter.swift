import Foundation

struct Interpreter: ExpressionVisitor
{
    typealias R = Any?

    // - MARK: Public
    public func interpret(expression: Expression)
    {
        do
        {
            let value = try self.evaluate(expression: expression)
            print( try Self.stringify(value) )
        }
        catch RuntimeError.ExpectedNumericOperand(let optr)
        {
            Lox.runtimeError(line: optr.line, message: "❌ RUNTIME ERROR: Expected numeric operand")
        }
        catch RuntimeError.MismatchingOperands(let optr)
        {
            Lox.runtimeError(
                line: optr.line,message: "❌ RUNTIME ERROR: Mismatching operands")
        }
        catch RuntimeError.DivisionByZero(let line)
        {
            Lox.runtimeError(line: line, message: "❌ RUNTIME ERROR: Division by 0")
        }
        catch
        {
            Lox.runtimeError(line: -1, message: "UNKOWN RUNTIME ERROR")
        }
    }



	public func visit(_ literalexp: LiteralExp) -> R
    {
        assert( literalexp.value != nil )
        switch literalexp.value
        {
            case .number(let n): return n
            case .string(let s): return s
            case .identifier(let i): return i // TODO:
            case .none: return nil
        }
    }


	public func visit(_ grouping: Grouping) throws -> R
    {
        try self.evaluate(expression: grouping.expression)
    }


	public func visit(_ unary: Unary) throws -> R
    {
        let right = try self.evaluate(expression: unary.right)

        switch unary.op.type
        {
            case .MINUS:
                try Self.validateNumericOperands(operator: unary.op, operands: right)
                return -(right as! Double)
            case .BANG:
                return !Self.isTruthful(right)
            default:
                return nil
        }
    }


	public func visit(_ binary: Binary) throws -> R
    {
        let left  = try self.evaluate(expression: binary.left)
        let right = try self.evaluate(expression: binary.right)

        switch binary.op.type
        {
            // Comparison
            case .GREATER:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) > (right as! Double)
            case .GREATER_EQUAL:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) >= (right as! Double)
            case .LESS:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) < (right as! Double)
            case .LESS_EQUAL:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) <= (right as! Double)

            // Equality
            case .EQUAL_EQUAL:
                return Self.areEqual(left, right)
            case .BANG_EQUAL:
                return !Self.areEqual(left, right)

            // Arithmetic
            case .MINUS:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) - (right as! Double)
            case .SLASH:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) / (right as! Double)
            case .STAR:
                try Self.validateNumericOperands(operator: binary.op, operands: left, right)
                return (left as! Double) * (right as! Double)
            case .PLUS:
                if
                    let left  = left  as? Double,
                    let right = right as? Double
                {
                    return left + right
                }
                else
                {
                    return try Self.stringify(left) + Self.stringify(right)
                }

            default:
                return nil
        }
    }


	public func visit(_ ternary: Ternary) throws -> R
    {
        let condition = try self.evaluate(expression: ternary.condition)
        if Self.isTruthful(condition)
        {
            return try self.evaluate(expression: ternary.then_branch)
        }
        else
        {
            return try self.evaluate(expression: ternary.else_branch)
        }
    }


    // - MARK: Private
    private func evaluate(expression: Expression) throws -> R { try expression.accept(visitor: self) }


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


    private static func validateNumericOperands(operator optr: Token, operands: Any?...) throws
    {
        // I don't want to deal with NaNs and Infinites XD
        if optr.type == .SLASH
        {
            assert(operands.count == 2)
            if operands[1] as! Double == 0.0
            {
                throw RuntimeError.DivisionByZero(line: optr.line)
            }
        }

        for operand in operands
        {
            if operand as? Double == nil
            {
                throw RuntimeError.ExpectedNumericOperand(operator: optr)
            }
        }
    }


    private static func stringify(_ obj: Any?) throws -> String
    {
        guard let obj = obj else
        {
            return "nil"
        }

        if let obj = obj as? Double
        {
            // If it's an integer remove the last 2 characters (.0)
            if obj.truncatingRemainder(dividingBy: 1.0) == 0.0
            {
                return String( obj.description.dropLast(2) )
            }
            return obj.description
        }
        else if let obj = obj as? String
        {
            return obj
        }

        throw RuntimeError.ObjectNonConvertibleToString
    }
}


enum RuntimeError: Error
{
    case ExpectedNumericOperand(operator: Token)
    case MismatchingOperands(operator: Token) // TODO: pass more info about the operands
    case DivisionByZero(line: Int)
    case ObjectNonConvertibleToString
}