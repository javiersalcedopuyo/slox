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

            case "/":
                if self.advance_if_next_matches("/")
                {
                    while peek() != "\n" && !self.is_at_end()
                    {
                        // Comments start with double slashes and go until the end of the line
                        _ = self.advance()
                    }
                }
                else
                {
                    add_token(type: .SLASH)
                }

            case " ", "\r", "\t":
                // Ignore whitespace
                break

            case "\n":
                self.current_line += 1

            default: Lox.error(
                        line: self.current_line,
                        message: "Unexpected character: \(c)")
        }
    }



    private mutating func add_string_token()
    {
        while self.peek() != "\"" && !self.is_at_end()
        {
            if self.peek() == "\n"
            {
                // Multi-line strings
                self.current_line += 1
            }
            _ = self.advance()
        }

        if self.is_at_end()
        {
            Lox.error(
                line: self.current_line,
                message: "Unterminated string.")
        }

        // Consume the closing quote
        _ = self.advance()

        // Trim the opening and closing quotes
        let start_idx = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_lexeme_start + 1)

        let end_idx = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_character - 1)

        // Add the actual string
        let text = String( self.source[start_idx..<end_idx] )
        // TODO: Unescape scape sequences
        self.add_token(type: .STRING, literal: .string(text))
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