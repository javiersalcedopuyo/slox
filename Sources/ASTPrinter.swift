struct ASTPrinter : Visitor
{
    typealias R = String

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