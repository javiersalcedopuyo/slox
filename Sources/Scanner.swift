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

            default:
                if is_digit(c)
                {
                    self.add_number_token()
                }
                else if is_letter(c) || c == "_"
                {
                    self.add_identifier_token()
                }
                else
                {
                    Lox.error(
                        line: self.current_line,
                        message: "Unexpected character: \(c)")
                }
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



    private mutating func add_number_token()
    {
        // Find the fractional divider `.`
        while is_digit( self.peek() )
        {
            _ = self.advance()
        }

        if self.peek() == "." && is_digit( self.peek_next() )
        {
            _ = self.advance() // Skip the divider
            // Get to the end of the decimal part
            while is_digit( self.peek() )
            {
                _ = self.advance()
            }
        }

        guard let number_literal = Double( self.get_current_lexeme() ) else
        {
            let error_mesage = "Current lexeme (\(self.get_current_lexeme())) is NaN."
            Lox.error(line:
                self.current_line,
                message: error_mesage)
            return
        }

        self.add_token(
            type: .NUMBER,
            literal: .number( number_literal ))
    }



    private mutating func add_identifier_token()
    {
        while is_alphanumeric( self.peek() )
        {
            _ = self.advance()
        }

        let lexeme = self.get_current_lexeme()
        // If the current lexeme matches a keyword it's a reserved word,
        // otherwise it's an user-defined identifier.
        let type = Self.KEYWORDS[lexeme] ?? .IDENTIFIER
        self.add_token(type: type)
    }



    /// Gets the next cahracter after self.current_character and increments the pointer
    /// - Returns: The next character after self.current_character
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



    /// Gets the current character being scanned
    /// - Returns: The Character pointed by self.current_character
    private func peek() -> Character
    {
        let index = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_character)
        return self.source[index]
    }



    /// Returns the next character after self.current_character _without_ advancing the pointer
    /// - Returns: The next character after self.current_character
    private func peek_next() -> Character
    {
        let index = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_character + 1)

        return self.source[index]
    }



    private mutating func add_token(
        type: TokenType,
        literal: Literal? = nil)
    {
        self.tokens.append(
            Token(
                type: type,
                lexeme: self.get_current_lexeme(),
                literal: literal,
                line: self.current_line))
    }



    private func get_current_lexeme() -> String
    {
        let start_idx = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_lexeme_start)

        let end_idx = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_character)

        return String( self.source[start_idx..<end_idx] )
    }


    // MARK: - Private members
    private let source: String
    private var tokens: [Token] = []

    // Indices
    private var current_lexeme_start:   Int = 0
    private var current_character:      Int = 0
    private var current_line:           Int = 1

    private static let KEYWORDS: [String: TokenType] =
    [
        "and":      .AND,
        "class":    .CLASS,
        "else":     .ELSE,
        "false":    .FALSE,
        "for":      .FOR,
        "fun":      .FUN,
        "if":       .IF,
        "nil":      .NIL,
        "or":       .OR,
        "print":    .PRINT,
        "return":   .RETURN,
        "super":    .SUPER,
        "this":     .THIS,
        "true":     .TRUE,
        "var":      .VAR,
        "while":    .WHILE
    ]
}
