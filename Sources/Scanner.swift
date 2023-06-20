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



    private func scan_token()
    {
        // TODO: self.advance()
    }



    // MARK: - Private members
    private let source: String
    private var tokens: [Token] = []

    // Indices
    private var current_lexeme_start:   Int = 0
    private var current_character:      Int = 0
    private var current_line:           Int = 1
}