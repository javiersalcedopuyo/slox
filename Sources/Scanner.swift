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
        guard let c = self.advance() else
        {
            return
        }

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
            case ":": add_token(type: .COLON)
            case ";": add_token(type: .SEMICOLON)
            case "*": add_token(type: .STAR)
            case "?": add_token(type: .QUESTION_MARK)

            case "!": add_token(type: advance_if_peek_matches("=") ? .BANG_EQUAL    : .BANG)
            case "=": add_token(type: advance_if_peek_matches("=") ? .EQUAL_EQUAL   : .EQUAL)
            case "<": add_token(type: advance_if_peek_matches("=") ? .LESS_EQUAL    : .LESS)
            case ">": add_token(type: advance_if_peek_matches("=") ? .GREATER_EQUAL : .GREATER)

            case "\"":
                let starting_line = self.current_line
                var string_literal: String = ""
                while !self.is_at_end() && self.peek() != "\""
                {
                    guard let c = self.peek() else
                    {
                        Lox.error(line: self.current_line, message: "Unexpected end of file.")
                        break
                    }
                    string_literal.append(c)
                    _ = self.advance()
                }

                if !self.advance_if_peek_matches("\"")
                {
                    Lox.error(line: starting_line, message: "Missing closing \"")
                }
                add_token(type: .STRING, literal: .string(string_literal))

            case "/":
                if self.advance_if_peek_matches("/") // Simple comment
                {
                    while self.peek() != "\n" && !self.is_at_end()
                    {
                        // Comments start with double slashes and go until the end of the line
                        _ = self.advance()
                    }
                }
                else if self.advance_if_peek_matches("*") // Block comment
                {
                    var block_count = 1
                    while !self.is_at_end()
                    {
                        let previous_character = self.advance()

                        let found_new_block =
                            previous_character == "/" &&
                            self.advance_if_peek_matches("*") // Automatically skip the `*`
                        if found_new_block
                        {
                            block_count += 1
                        }

                        let reached_closing =
                            previous_character == "*" &&
                            self.advance_if_peek_matches("/") // Automatically skip the closing `/`
                        if reached_closing
                        {
                            block_count -= 1
                        }

                        if block_count < 1
                        {
                            break
                        }
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
                        message: "Unexpected character: \(String(describing: c))")
                }
        }
    }



    private mutating func add_string_token()
    {
        while !self.is_at_end() && self.peek() != "\""
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
        while is_digit( self.peek() ?? "\0" )
        {
            _ = self.advance()
        }

        if self.peek() == "." && is_digit( self.peek_next() ?? "\0" )
        {
            _ = self.advance() // Skip the divider
            // Get to the end of the decimal part
            while !self.is_at_end() && is_digit( self.peek() ?? "\0" )
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
        while !self.is_at_end()
            && ( is_alphanumeric( self.peek() ?? "\0" ) || self.peek() == "_" )
        {
            _ = self.advance()
        }

        let lexeme = self.get_current_lexeme()
        // If the current lexeme matches a keyword it's a reserved word,
        // otherwise it's an user-defined identifier.
        let type = Self.KEYWORDS[lexeme] ?? .IDENTIFIER
        self.add_token(type: type)
    }



    /// Gets the cahracter pointed by self.current_character and advances the pointer.
    /// - Returns: The character pointed by self.current_character. Nil if out of bounds.
    private mutating func advance() -> Character?
    {
        defer { self.current_character += 1 }
        return peek()
    }



    /// Advances `self.current_character` only if the character it points to matches the input
    /// - Parameter expected: The character to compare
    /// - Returns: `true` if it has advanced, `false` if it hasn't
    private mutating func advance_if_peek_matches(_ expected: Character) -> Bool
    {
        if self.is_at_end() || peek() != expected
        {
            return false
        }

        self.current_character += 1
        return true
    }



    /// Gets the current character being scanned.
    /// - Returns: The Character pointed by self.current_character. Nil if out of bounds.
    private func peek() -> Character?
    {
        if self.is_at_end()
        {
            return nil
        }

        let index = self.source.index(
            self.source.startIndex,
            offsetBy: self.current_character)
        return self.source[index]
    }



    /// Returns the next character after self.current_character _without_ advancing the pointer
    /// - Returns: The next character after self.current_character. `Nil` if out of bounds.
    private func peek_next() -> Character?
    {
        if self.current_character + 1 >= self.source.count
        {
            return nil
        }

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
        "while":    .WHILE,
        "break":    .BREAK,
        "continue": .CONTINUE
    ]
}
