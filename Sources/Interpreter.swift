import Foundation

struct Interpreter: ExpressionVisitor, StatementVisitor
{
    typealias R = Any?

    public let global_scope: Environment

    public init()
    {
        self.global_scope = Environment()
        self.global_scope.define(name: "clock", value: ClockPrimitive())

        self.current_scope = self.global_scope
    }

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
        catch RuntimeError.UncallableCallee(let line)
        {
            Lox.runtimeError(
                line: line,
                message: "❌ RUNTIME ERROR: Only functions and classes (constructors) can be called.")
        }
        catch RuntimeError.MismatchingArity(let line, let expected, let found)
        {
            Lox.runtimeError(
                line: line,
                message:
                    "❌ RUNTIME ERROR: "
                    + "Function called expected \(expected) arguments but \(found) were provided.")
        }
        catch FlowBreakers.Break, FlowBreakers.Continue
        {
            fatalError(
                "💀 FATAL RUNTIME ERROR: Break or Continue statement outside of loop!\n" +
                "This should never happen as it should've been caught by the parser!")
        }
        catch
        {
            Lox.runtimeError(line: -1, message: "? UNKOWN RUNTIME ERROR")
        }
    }


    public mutating func visit(_ assignment: Assignment) throws -> R
    {
        let value = try self.evaluate(expression: assignment.value)

        if let distance = self.locals[assignment.uuid]
        {
            try self.current_scope.assign(
                at_distance: distance,
                name: assignment.name,
                value: assignment.value)
        }
        else
        {
            try self.global_scope.assign(name: assignment.name, value: value)
        }
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
            case .keyword(let k):
                switch k
                {
                    case "false": return false
                    case "true": return true
                    default: return nil
                }
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


    public mutating func visit(_ logical: Logical) throws -> Any?
    {
        let left = try self.evaluate(expression: logical.left)
        let is_left_true = Self.isTruthful(left)

        if logical.op.type == .OR
        {
            if is_left_true
            {
                return true
            }
        }
        else
        {
            if !is_left_true
            {
                return false
            }
        }

        let right = try self.evaluate(expression: logical.right)
        let is_right_true = Self.isTruthful(right)

        if logical.op.type == .OR
        {
            return is_right_true
        }
        else
        {
            return is_left_true && is_right_true
        }
    }


    public mutating func visit(_ call: Call) throws -> Any?
    {
        let callee = try self.evaluate(expression: call.callee)

        guard let function = callee as? Callable else
        {
            throw RuntimeError.UncallableCallee(line: call.parenthesis.line)
        }

        var arguments: [R] = []
        for argument in call.arguments
        {
            arguments.append( try self.evaluate(expression: argument) )
        }

        if arguments.count != function.arity
        {
            throw RuntimeError.MismatchingArity(
                line: call.parenthesis.line,
                expected: function.arity,
                found: arguments.count)
        }

        return try function.call(interpreter: &self, arguments: arguments)
    }

    public mutating func visit(_ function: FunExpression) throws -> R
    {
        return Function(declaration: function, closure: self.current_scope)
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

        self.current_scope.define(name: variable.name.lexeme, value: value)
        return nil
    }


    public mutating func visit(_ funstatement: FunStatement) throws -> Any?
    {
        let function = Function(declaration: funstatement.function, closure: self.current_scope)
        self.current_scope.define(name: funstatement.name.lexeme, value: function)
        return nil
    }


    public mutating func visit(_ block: Block) throws -> R
    {
        try self.execute(
            block: block,
            environment: Environment(in_scope: self.current_scope))
    }


    public mutating func visit(_ whilestatement: WhileStatement) throws -> Any?
    {
        while Self.isTruthful( try self.evaluate(expression: whilestatement.condition) )
        {
            do
            {
                try self.execute(statement: whilestatement.body)
            }
            catch FlowBreakers.Break
            {
                break
            }
            // TODO: Continue
            catch
            {
                throw error
            }
        }
        return nil
    }


    public mutating func visit(_ conditionalstatement: ConditionalStatement) throws -> R
    {
        if Self.isTruthful( try self.evaluate(expression: conditionalstatement.condition) )
        {
            try self.execute(statement: conditionalstatement.then_branch)
        }
        else if let else_branch = conditionalstatement.else_branch
        {
            try self.execute(statement: else_branch)
        }
        return nil
    }


    public mutating func visit(_ variable: Variable) throws -> R
    {
        try self.current_scope.get(name: variable.name)
    }


    public mutating func visit(_ breakstatement: BreakStatement) throws -> Any?
    {
        throw FlowBreakers.Break
    }


    public mutating func visit(_ returnstatment: ReturnStatment) throws -> Any?
    {
        let value = returnstatment.value != nil
            ? try self.evaluate(expression: returnstatment.value!)
            : nil

        throw FlowBreakers.Return(value)
    }


    mutating public func execute(block: Block, environment scope: Environment) throws
    {
        let previous_environment = self.current_scope
        defer { self.current_scope = previous_environment }

        self.current_scope = scope
        for statement in block.statements
        {
            try self.execute(statement: statement)
        }
    }


    mutating public func execute(statement: Statement) throws { try _ = statement.accept(visitor: &self) }


    mutating public func resolve(expression: Expression, depth: Int) { self.locals[expression.uuid] = depth }


    // - MARK: Private
    mutating private func evaluate(expression: Expression) throws -> R { try expression.accept(visitor: &self) }


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
        else if let obj = obj as? Bool
        {
            return obj ? "true" : "false"
        }

        throw RuntimeError.ObjectNonConvertibleToString
    }


    private func look_up(variable_name name: Token, expression: Expression) throws -> Any?
    {
        guard let distance = self.locals[expression.uuid] else
        {
            return try self.global_scope.get(name: name)
        }

        return try self.current_scope.get(at_distance: distance, name: name)
    }


    private var current_scope: Environment

    private var locals: [UUID: Int] = [:]
}


enum RuntimeError: Error
{
    case ExpectedNumericOperand(operator: Token)
    case MismatchingOperands(operator: Token) // TODO: pass more info about the operands
    case DivisionByZero(line: Int)
    case ObjectNonConvertibleToString
    case UndeclaredVariable(variable: Token)
    case UndefinedVariable(variable: Token)
    case UncallableCallee(line: Int)
    case MismatchingArity(line: Int, expected: Int, found: Int)
    case LocalVariableNotFoundAtExpectedDepth(name: String, depth: Int)
}


enum FlowBreakers: Error
{
    case Break
    case Continue
    case Return(Any?)
}
