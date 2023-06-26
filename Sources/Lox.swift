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
            case 0:     lox.run_prompt()
            case 1:     lox.run(file: arguments[0])
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
            fatalError("Failed to read file")
        }

        self.run(source: file_contents)

        if (Self.had_error)
        {
            fatalError()
        }
    }



    private func run(source: String)
    {
        let scanner = Scanner(source: source)
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