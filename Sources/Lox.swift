import Foundation

@main
class Lox
{
    public static func main()
    {
        let lox = Lox()

        let arguments = CommandLine.arguments
        switch arguments.count
        {
            // NOTE: There's always at least 1 argument, the path to the executable
            case 1:     lox.run_prompt()
            case 2:     lox.run(file: arguments[1])
            default:    fatalError("Too many arguments. Usage: slox [script]")
        }
    }



    // MARK: - Public methods
    public static func error(
        line:     Int,
        message:  String)
    {
        Self.had_error = true
        Self.report(line: line, where: "", message: message)
    }


    public static func runtimeError(
        line:     Int,
        message:  String)
    {
        Self.had_runtime_error = true
        Self.report(line: line, where: "", message: message)
    }



    // MARK: - Private methods
    private func run_prompt()
    {
        print("Input next command:")
        while let line = readLine()
        {
            if line == "q" || line == "quit" || line == "exit"
            {
                break
            }

            self.run(source: line, repl_mode: true)
            Self.had_error = false

            print("---")
            print("Input next command:")
        }
    }



    private func run(file file_name: String)
    {
        guard let file_contents = try? String(contentsOf: URL(fileURLWithPath: file_name),
                                              encoding: .utf8)
        else
        {
            fatalError("Failed to read file \(file_name)")
        }

        self.run(source: file_contents, repl_mode: false)

        if Self.had_error
        {
            exit(65)
        }
        if Self.had_runtime_error
        {
            exit(70)
        }
    }



    private func run(source: String, repl_mode: Bool)
    {
        var scanner     = Scanner(source: source)
        let tokens      = scanner.scan_tokens()
        var parser      = Parser(tokens: tokens)
        let statements  = parser.parse()

        if Self.had_error == true || statements.count == 0
        {
            return;
        }

        let resolver = Resolver(interpreter: Self.interpreter)
        do
        {
            try resolver.resolve(statements: statements)
        }
        catch
        {
            fatalError("Unknown Resolver error. We should never get here! Error: \(error)")
        }

        if Self.had_error
        {
            return
        }


        Self.interpreter.interpret(statements: statements, repl_mode: repl_mode)
    }



    private static func report(
        line:           Int,
        where location: String,
        message:        String)
    {
        print("[", location, ":", line, "] ", message)
    }



    // MARK: - Members
    private static var had_error = false
    private static var had_runtime_error = false
    private static var interpreter = Interpreter()
}
