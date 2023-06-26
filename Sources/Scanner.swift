struct Scanner
{
    init(source: String)
    {
        self.source = source
    }



    // MARK: - Public methods
    mutating func scan_tokens() -> [Token]
    {
        while (!self.is_at_end())
        {
            self.current_lexeme_start = self.current_character
            self.scan_token()
        }

        self.tokens.append(
            Token(type:     .EOF,
                  lexeme:   "",
                  literal:  nil,
                  line:     self.current_line))

        return self.tokens
    }



    // MARK: - Private methods
    private func is_at_end() -> Bool { current_character >= source.count }



    private mutating func scan_token()
    {
        let c = self.advance()
        switch c
        {
            case "(": add_token(type: .LEFT_PARENTHESIS)
            case ")": add_token(type: .RIGHT_PARENTHESIS)
            case "{": add_token(type: .LEFT_BRACE)
            case "}": add_token(type: .RIGHT_BRACE)
            case ",": add_token(type: .COMMA)
            case ".": add_token(type: .DOT)
            case "-": add_token(type: .MINUS)
            case "+": add_token(type: .PLUS)
            case ";": add_token(type: .SEMICOLON)
            case "*": add_token(type: .STAR)

            case "!": add_token(type: advance_if_next_matches("=") ? .BANG_EQUAL    : .BANG)
            case "=": add_token(type: advance_if_next_matches("=") ? .EQUAL_EQUAL   : .EQUAL)
            case "<": add_token(type: advance_if_next_matches("=") ? .LESS_EQUAL    : .LESS)
            case ">": add_token(type: advance_if_next_matches("=") ? .GREATER_EQUAL : .GREATER)

            default: Lox.error(
                        line: self.current_line,
                        message: "Unexpected character: \(c)")
        }
    }



    private mutating func advance() -> Character
    {
        defer { self.current_character += 1 }
        return peek()
    }



    private mutating func advance_if_next_matches(_ expected: Character) -> Bool
    {
        if self.is_at_end() || peek() != expected
        {
            return false
        }

        self.current_character += 1
        return true
    }



    private func peek() -> Character
    {
        let index = self.source.index(self.source.startIndex, offsetBy: self.current_character)
        return self.source[index]
    }



    private mutating func add_token(
        type: TokenType,
        literal: Literal? = nil)
    {
        let start_idx = self.source.index(self.source.startIndex, offsetBy: self.current_lexeme_start)
        let end_idx   = self.source.index(self.source.startIndex, offsetBy: self.current_character)
        let text = self.source[start_idx..<end_idx]

        self.tokens.append(
            Token(
                type: type,
                lexeme: String(text),
                literal: literal,
                line: self.current_line))
    }


    // MARK: - Private members
    private let source: String
    private var tokens: [Token] = []

    // Indices
    private var current_lexeme_start:   Int = 0
    private var current_character:      Int = 0
    private var current_line:           Int = 1
}