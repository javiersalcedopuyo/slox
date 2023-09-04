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
        Self.report(line: line, where: "", message: message)
    }



    // MARK: - Private methods
    private func run_prompt()
    {
        print("Input commands:")
        while let line = readLine()
        {
            if line == "q" || line == "quit" || line == "exit"
            {
                break
            }

            self.run(source: line)
            Self.had_error = false
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

        self.run(source: file_contents)

        if (Self.had_error)
        {
            fatalError()
        }
    }



    private func run(source: String)
    {
        var scanner = Scanner(source: source)
        let tokens = scanner.scan_tokens()

        for token in tokens
        {
            // TODO:
            print(token)
        }
    }



    private static func report(
        line:           Int,
        where location: String,
        message:        String)
    {
        print("[", location, ":", line, "] ", message)
        Self.had_error = true
    }



    // MARK: - Members
    private static var had_error = false
}