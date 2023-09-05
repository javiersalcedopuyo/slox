import XCTest
@testable import slox

final class ScannerTests: XCTestCase
{
    func testSingleIdentifier()
    {
        let source = "asdf"
        var scanner = Scanner(source: source)
        let tokens  = scanner.scan_tokens()

        XCTAssertEqual( tokens.count, 2 )
        XCTAssertEqual( tokens[0].type, .IDENTIFIER )
        XCTAssertEqual( tokens[0].lexeme, "asdf" )
        XCTAssertEqual( tokens[1].type, .EOF )
    }



    func testMultipleTokensInOneLine()
    {
        let source = "a = 1"
        var scanner = Scanner(source: source)
        let tokens  = scanner.scan_tokens()

        XCTAssertEqual( tokens.count, 4 )
        XCTAssertEqual( tokens[0].type, .IDENTIFIER )
        XCTAssertEqual( tokens[0].lexeme, "a" )

        XCTAssertEqual( tokens[1].type, .EQUAL )

        XCTAssertEqual( tokens[2].type, .NUMBER )
        XCTAssertEqual( tokens[2].lexeme, "1" )

        XCTAssertEqual( tokens[3].type, .EOF )
    }



    func testMultipleLines()
    {
        let source = """
            asdf
            qwer
            """
        var scanner = Scanner(source: source)
        let tokens  = scanner.scan_tokens()

        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].type, .IDENTIFIER)
        XCTAssertEqual(tokens[0].lexeme, "asdf")

        XCTAssertEqual(tokens[1].type, .IDENTIFIER)
        XCTAssertEqual(tokens[1].lexeme, "qwer")

        XCTAssertEqual(tokens[2].type, .EOF)
    }



    func testSimpleComment()
    {
        let source = """
            // this is a comment
            asdf
            """
        var scanner = Scanner(source: source)
        let tokens  = scanner.scan_tokens()

        XCTAssertEqual( tokens.count, 2 )
        XCTAssertEqual( tokens[0].type, .IDENTIFIER )
        XCTAssertEqual( tokens[0].lexeme, "asdf" )
        XCTAssertEqual( tokens[1].type, .EOF )
    }
}
