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

        let types = [
            "Binary: Expression left, Token op, Expression right",
            "Grouping: Expression expression",
            "LiteralExp: Literal? value",
            "Unary: Token op, Expression right"
        ]

        do
        {
            try define_AST(
                output_directory: output_dir,
                base_name: "Expression",
                types: types)
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

    var output = define_visitor(base_name: base_name, types: types)
    output += "\n\n\n"

    output += "protocol " + base_name + "\n"
    output += "{\n"
    output += "\tfunc accept<R, V: Visitor>(visitor: V) -> R where V.R == R\n"
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
    var output = "protocol Visitor\n"
    output += "{\n"
    output += "\tassociatedtype R\n\n"

    for type in types
    {
        let type_name = type
            .split(separator: ":")[0]
            .trimmingCharacters(in: .whitespaces)

        output += "\tfunc visit(_ "
        output += type_name.lowercased() + ": " + type_name
        output += ") -> R\n"
    }

    output += "}\n"
    return output
}



func parse_sub_type(base_name: String, descriptor: String) -> String
{
    // I'm assuming the input will be properly formatted.
    // Not great but this is just to automate some boilerplate.

    let class_name = descriptor.split(separator: ":")[0]
        .trimmingCharacters(in: .whitespaces)

    var output = "\n\n\n"
    output += "struct " + class_name + ": " + base_name + "\n"
    output += "{\n"

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
    output += "\tfunc accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }\n"

    output += "}\n"
    return output
}