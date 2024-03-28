class ASTPrinter : ExpressionVisitor
{
    typealias R = String

    public func print(expression: any Expression) -> String
    {
        do
        {
            return try expression.accept(visitor: self)
        }
        catch
        {
            fatalError("This should be unreachable! Error: \(error)")
        }
    }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ binary: Binary) throws -> String
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
    public func visit(_ grouping: Grouping) throws -> String
    {
        try parenthesize(name: "group", expressions: grouping.expression)
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
    public func visit(_ unary: Unary) throws -> String
    {
        try parenthesize(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" a `Ternary` expression
    /// - Parameter ternary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ ternary: Ternary) throws -> String
    {
        try parenthesize(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }



    /// "Prettyfies" a `This` expression
    /// - Parameter this: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ this: ThisExpression) throws -> String
    {
        this.keyword.lexeme
    }



    /// "Prettyfies" a `Logical` expression
    /// - Parameter logical: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ logical: Logical) throws -> String
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
    public func visit(_ variable: Variable) -> String { variable.name.lexeme }



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



    /// "Prettyfies" a `Getter` expression
    /// - Parameter getter: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ getter: Getter) -> String
    {
        // TODO:
        getter.name.lexeme
    }



    /// "Prettyfies" a `Setter` expression
    /// - Parameter setter: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ setter: Setter) -> String
    {
        // TODO:
        setter.property.lexeme
    }



    /// "Prettyfies" a `Function` expression
    /// - Parameter call: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ function: FunExpression) -> String
    {
        // TODO:
        "function expression (TODO)"
    }



    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private func parenthesize(name: String, expressions: Expression...) throws -> String
    {
        var output = "(" + name
        for expression in expressions
        {
            output += " "
            output += try expression.accept(visitor: self)
        }
        output += ")"
        return output
    }
}



struct ASTPrinterReversePolishNotation: ExpressionVisitor
{
    typealias R = String

    public func print(expression: any Expression) -> String
    {
        do
        {
            return try expression.accept(visitor: self)
        }
        catch
        {
            fatalError("This should be unreachable! Error: \(error)")
        }
    }

    /// "Prettyfies" a `Binary` expression
    /// - Parameter binary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ binary: Binary) throws -> String
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
    public func visit(_ grouping: Grouping) throws -> String
    {
        try convert_to_RPN(name: "group", expressions: grouping.expression)
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
    public func visit(_ unary: Unary) throws -> String
    {
        try convert_to_RPN(name: unary.op.lexeme, expressions: unary.right)
    }



    /// "Prettyfies" an `Unary` expression
    /// - Parameter unary: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ ternary: Ternary) throws -> String
    {
        try convert_to_RPN(
            name: "?:",
            expressions:
                ternary.condition,
                ternary.then_branch,
                ternary.else_branch)
    }



    /// "Prettyfies" a `This` expression
    /// - Parameter this: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ this: ThisExpression) throws -> String
    {
        this.keyword.lexeme
    }


    /// "Prettyfies" a `Logical` expression
    /// - Parameter logical: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ logical: Logical) throws -> String
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
    public func visit(_ variable: Variable) -> String { variable.name.lexeme }



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



    /// "Prettyfies" n `Getter` expression
    /// - Parameter getter: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ getter: Getter) -> String
    {
        // TODO:
        getter.name.lexeme
    }



    /// "Prettyfies" n `Setter` expression
    /// - Parameter setter: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ setter: Setter) -> String
    {
        // TODO:
        setter.property.lexeme
    }



    /// "Prettyfies" a `Function` expression
    /// - Parameter call: The expression to transform
    /// - Returns: The "prettyfied" expression
    public func visit(_ function: FunExpression) -> String
    {
        // TODO:
        "function expression (TODO)"
    }



    /// Prints expressions wrapping grouping and nesting in parenthesis
    /// - Parameters:
    ///   - name:
    ///   - expressions:
    /// - Returns: The wrapped expression(s)
    private func convert_to_RPN(name: String, expressions: Expression...) throws -> String
    {
        var output = ""
        for expression in expressions
        {
            output += try expression.accept(visitor: self) + " "
        }

        return output + name + " "
    }
}
