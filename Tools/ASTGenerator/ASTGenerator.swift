import Foundation;

@main
struct ASTGenerator
{
    public static func main()
    {
        let arguments = CommandLine.arguments

        if arguments.count != 2 // The first argument is the path to the executable
        {
            fatalError("Output directory needs to be provided.")
        }

        let output_dir = arguments[1]

        do
        {
            try define_AST(
                output_directory: output_dir,
                base_name: "Expression",
                types: [
                    "Assignment: Token name, Expression value",
                    "Binary: Expression left, Token op, Expression right",
                    "Call: Expression callee, Token parenthesis, [Expression] arguments",
                    "Getter: Expression obj, Token name",
                    "Grouping: Expression expression",
                    "LiteralExp: Literal? value",
                    "Logical: Expression left, Token op, Expression right",
                    "Setter: Expression obj, Token property, Expression value",
                    "ThisExpression: Token keyword",
                    "Unary: Token op, Expression right",
                    "Ternary: Expression condition, Expression then_branch, Expression else_branch",
                    "Variable: Token name",
                    "FunExpression: [Token] parameters, Block body, FunctionType type"])

            try define_AST(
                output_directory: output_dir,
                base_name: "Statement",
                types: [
                    "Block: [Statement] statements",
                    "ExpressionStatement: Expression expression",
                    "ConditionalStatement: Expression condition, Statement then_branch, Statement? else_branch",
                    "FunStatement: Token name, FunExpression function",
                    "WhileStatement: Expression condition, Statement body",
                    "BreakStatement",
                    // TODO: ContinueStatement
                    "Print: Expression expression",
                    "VarStatement: Token name, Expression? initializer",
                    "ReturnStatment: Token keyword, Expression? value",
                    "ClassDeclaration: Token name, [FunStatement] methods"])
        }
        catch
        {
            print("ERROR: \(error)")
        }
    }
}



func define_AST(
    output_directory: String,
    base_name:        String,
    types:            [String])
throws
{
    let output_path = (output_directory as NSString)
        .expandingTildeInPath +
        "/" + base_name + ".swift"

    let output_url = URL(fileURLWithPath: output_path)

    var output = "import Foundation\n\n"

    output += define_visitor(base_name: base_name, types: types)
    output += "\n\n\n"

    output += "protocol " + base_name + "\n"
    output += "{\n"
    output += "\tfunc accept<R, V: \(base_name)Visitor>(visitor: V) throws -> R where V.R == R\n"
    output += "\tvar uuid: UUID {get}\n"
    output += "}\n"

    for type in types
    {
        output += parse_sub_type(base_name: base_name, descriptor: type)
    }

    try output.write(
        to: output_url,
        atomically: true,
        encoding: .utf8)
}




func define_visitor(base_name: String, types: [String]) -> String
{
    var output = "protocol \(base_name)Visitor\n"
    output += "{\n"
    output += "\tassociatedtype R\n\n"

    for type in types
    {
        let type_name = type
            .split(separator: ":")[0]
            .trimmingCharacters(in: .whitespaces)

        output += "\t func visit(_ \(type_name.lowercased()): \(type_name)) throws -> R\n"
    }

    output += "}\n"
    return output
}



func parse_sub_type(base_name: String, descriptor: String) -> String
{
    // I'm assuming the input will be properly formatted.
    // Not great but this is just to automate some boilerplate.

    let class_and_fields = descriptor.split(separator: ":")
    assert(class_and_fields.count > 0) // At least there should be a class name

    let class_name = class_and_fields[0].trimmingCharacters(in: .whitespaces)

    var output = "\n\n\n"
    output += "struct " + class_name + ": " + base_name + "\n"
    output += "{\n"

    if class_and_fields.count > 1
    {
        let fields = descriptor.split(separator: ":")[1]
            .trimmingCharacters(in: .whitespaces)
            .split(separator: ",")

        for field in fields
        {
            // Not the most efficient but whatever...
            let type = field
                .trimmingCharacters(in: .whitespaces)
                .split(separator: " ")[0]

            let name = field
                .trimmingCharacters(in: .whitespaces)
                .split(separator: " ")[1]

            output += "\tlet " + name + ": " + type + "\n"
        }
        output += "\n"
    }
    output += "\tfunc accept<R, V: \(base_name)Visitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }\n"
    output += "\tlet uuid = UUID()\n"

    output += "}\n"
    return output
}
