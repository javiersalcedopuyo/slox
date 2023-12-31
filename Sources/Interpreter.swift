import Foundation

struct Interpreter: ExpressionVisitor, StatementVisitor
{
    typealias R = Any?

    // - MARK: Public
    mutating public func interpret(statements: [Statement], repl_mode: Bool)
    {
        do
        {
            for var statement in statements
            {
                if repl_mode
                {
                    if let expr = statement as? ExpressionStatement
                    {
                        statement = Print(expression: expr.expression)
                    }
                }
                try self.execute(statement: statement)
            }
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
        catch RuntimeError.UndeclaredVariable(let variable)
        {
            Lox.runtimeError(
                line: variable.line,
                message: "❌ RUNTIME ERROR: Undeclared variable `\(variable.lexeme)`.")
        }
        catch RuntimeError.UndefinedVariable(let variable)
        {
            Lox.runtimeError(
                line: variable.line,
                message: "❌ RUNTIME ERROR: Undefined variable `\(variable.lexeme)`.")
        }
        catch
        {
            Lox.runtimeError(line: -1, message: "? UNKOWN RUNTIME ERROR")
        }
    }


    public mutating func visit(_ assignment: Assignment) throws -> R
    {
        let value = try self.evaluate(expression: assignment.value)
        try self.environment.assign(name: assignment.name, value: value)
        return value
    }


	public mutating func visit(_ literalexp: LiteralExp) -> R
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


	public mutating func visit(_ grouping: Grouping) throws -> R
    {
        try self.evaluate(expression: grouping.expression)
    }


	public mutating func visit(_ unary: Unary) throws -> R
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


	public mutating func visit(_ binary: Binary) throws -> R
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


	public mutating func visit(_ ternary: Ternary) throws -> R
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


    public mutating func visit(_ statement: ExpressionStatement) throws -> R
    {
        _ = try self.evaluate(expression: statement.expression)
        return nil
    }


    public mutating func visit(_ statement: Print) throws -> R
    {
        let value = try self.evaluate(expression: statement.expression)
        print( try Self.stringify(value) )
        return nil
    }


    public mutating func visit(_ variable: VarStatement) throws -> R
    {
        var value = Optional<Any>.none // So the dictionary in `Environment` still considers it a valid entry
        if let initializer = variable.initializer
        {
            value = try self.evaluate(expression: initializer)
        }

        self.environment.define(name: variable.name.lexeme, value: value)
        return nil
    }


    public mutating func visit(_ block: Block) throws -> R
    {
        try self.execute(
            block: block,
            environment: Environment(in_scope: self.environment))
    }


    public mutating func visit(_ variable: Variable) throws -> R
    {
        try self.environment.get(name: variable.name)
    }


    // - MARK: Private
    mutating private func evaluate(expression: Expression) throws -> R { try expression.accept(visitor: &self) }


    mutating private func execute(block: Block, environment scope: Environment) throws
    {
        let previous_environment = self.environment
        defer { self.environment = previous_environment }

        self.environment = scope
        for statement in block.statements
        {
            try self.execute(statement: statement)
        }
    }


    mutating private func execute(statement: Statement) throws { try _ = statement.accept(visitor: &self) }


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


    private var environment = Environment()
}


enum RuntimeError: Error
{
    case ExpectedNumericOperand(operator: Token)
    case MismatchingOperands(operator: Token) // TODO: pass more info about the operands
    case DivisionByZero(line: Int)
    case ObjectNonConvertibleToString
    case UndeclaredVariable(variable: Token)
    case UndefinedVariable(variable: Token)
}