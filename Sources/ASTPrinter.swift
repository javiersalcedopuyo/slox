struct ASTPrinter : ExpressionVisitor
{
    typealias R = String

    public mutating func print(expression: any Expression) -> String
    {
        do
        {
            return try expression.accept(visitor: &self)
        }
        catch
        {
            fatalError("This should be unreachable! Error: \(error)")
        }
    }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ binary: Binary) throws -> String
    {
        try parenthesize(
            name: binary.op.lexeme,
            expressions:
                binary.left,
                binary.right)
    }



    /// "Prettyfies" a `Grouping` expression
    /// - Parameter grouping: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ grouping: Grouping) throws -> String
    {
        try parenthesize(name: "group", expressions: grouping.expression)
    }



    /// "Prettyfies" a `LiteralExp` expression
    /// - Parameter literalexp: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ literalexp: LiteralExp) -> String
    {
        guard let value = literalexp.value else
        {
            return "nil"
        }
        return value.to_string()
    }



    /// "Prettyfies" an `Unary` expression
    /// - Parameter unary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ unary: Unary) throws -> String
    {
        try parenthesize(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" a `Ternary` expression
    /// - Parameter ternary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ ternary: Ternary) throws -> String
    {
        try parenthesize(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }



    /// "Prettyfies" a `Logical` expression
    /// - Parameter logical: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ logical: Logical) throws -> String
    {
        try parenthesize(
            name: logical.op.lexeme,
            expressions:
                logical.left,
                logical.right)
    }



    /// "Prettyfies" a `Variable` expression
    /// - Parameter variable: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ variable: Variable) -> String { variable.name.lexeme }



    /// "Prettyfies" an `Assignment` expression
    /// - Parameter assignment: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ assignment: Assignment) -> String
    {
        // TODO:
        assignment.name.lexeme
    }



    /// "Prettyfies" an `Call` expression
    /// - Parameter call: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ call: Call) -> String
    {
        // TODO:
        "function call (TODO)"
    }



    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private mutating func parenthesize(name: String, expressions: Expression...) throws -> String
    {
        var output = "(" + name
        for expression in expressions
        {
            output += " "
            output += try expression.accept(visitor: &self)
        }
        output += ")"
        return output
    }
}



struct ASTPrinterReversePolishNotation: ExpressionVisitor
{
    typealias R = String

    public mutating func print(expression: any Expression) -> String
    {
        do
        {
            return try expression.accept(visitor: &self)
        }
        catch
        {
            fatalError("This should be unreachable! Error: \(error)")
        }
    }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ binary: Binary) throws -> String
    {
        try convert_to_RPN(
            name: binary.op.lexeme,
            expressions:
                binary.left,
                binary.right)
    }



    /// "Prettyfies" a `Grouping` expression
    /// - Parameter grouping: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ grouping: Grouping) throws -> String
    {
        try convert_to_RPN(name: "group", expressions: grouping.expression)
    }



    /// "Prettyfies" a `LiteralExp` expression
    /// - Parameter literalexp: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ literalexp: LiteralExp) -> String
    {
        guard let value = literalexp.value else
        {
            return "nil"
        }
        return value.to_string()
    }



    /// "Prettyfies" an `Unary` expression
    /// - Parameter unary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ unary: Unary) throws -> String
    {
        try convert_to_RPN(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" an `Unary` expression
    /// - Parameter unary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ ternary: Ternary) throws -> String
    {
        try convert_to_RPN(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }


    /// "Prettyfies" a `Logical` expression
    /// - Parameter logical: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ logical: Logical) throws -> String
    {
        try convert_to_RPN(
            name: logical.op.lexeme,
            expressions:
                logical.left,
                logical.right)
    }



    /// "Prettyfies" a `Variable` expression
    /// - Parameter variable: The expression to transform
    /// - Returns: The "prettyfied" expression
    public mutating func visit(_ variable: Variable) -> String { variable.name.lexeme }



    /// "Prettyfies" an `Assignment` expression
    /// - Parameter assignment: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ assignment: Assignment) -> String
    {
        // TODO:
        assignment.name.lexeme
    }



    /// "Prettyfies" an `Call` expression
    /// - Parameter call: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ call: Call) -> String
    {
        // TODO:
        "function call (TODO)"
    }




    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private mutating func convert_to_RPN(name: String, expressions: Expression...) throws -> String
    {
        var output = ""
        for expression in expressions
        {
            output += try expression.accept(visitor: &self) + " "
        }

        return output + name + " "
    }
}