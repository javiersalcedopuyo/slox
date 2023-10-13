struct ASTPrinter : Visitor
{
    typealias R = String

    public func print(expression: any Expression) -> String { expression.accept(visitor: self) }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ binary: Binary) -> String
    {
        parenthesize(
            name: binary.op.lexeme,
            expressions:
                binary.left,
                binary.right)
    }



    /// "Prettyfies" a `Grouping` expression
    /// - Parameter grouping: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ grouping: Grouping) -> String
    {
        parenthesize(name: "group", expressions: grouping.expression)
    }



    /// "Prettyfies" a `LiteralExp` expression
    /// - Parameter literalexp: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ literalexp: LiteralExp) -> String
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
    public func visit(_ unary: Unary) -> String
    {
        parenthesize(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" a `Ternary` expression
    /// - Parameter ternary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ ternary: Ternary) -> String
    {
        parenthesize(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }



    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private func parenthesize(name: String, expressions: Expression...) -> String
    {
        var output = "(" + name
        for expression in expressions
        {
            output += " "
            output += expression.accept(visitor: self)
        }
        output += ")"
        return output
    }
}



struct ASTPrinterReversePolishNotation: Visitor
{
    typealias R = String

    public func print(expression: any Expression) -> String { expression.accept(visitor: self) }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ binary: Binary) -> String
    {
        convert_to_RPN(
            name: binary.op.lexeme,
            expressions:
                binary.left,
                binary.right)
    }



    /// "Prettyfies" a `Grouping` expression
    /// - Parameter grouping: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ grouping: Grouping) -> String
    {
        convert_to_RPN(name: "group", expressions: grouping.expression)
    }



    /// "Prettyfies" a `LiteralExp` expression
    /// - Parameter literalexp: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ literalexp: LiteralExp) -> String
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
    public func visit(_ unary: Unary) -> String
    {
        convert_to_RPN(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" an `Unary` expression
    /// - Parameter unary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ ternary: Ternary) -> String
    {
        convert_to_RPN(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }



    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private func convert_to_RPN(name: String, expressions: Expression...) -> String
    {
        var output = ""
        for expression in expressions
        {
            output += expression.accept(visitor: self) + " "
        }

        return output + name + " "
    }
}