import XCTest
@testable import slox

final class ASTPrinterTests: XCTestCase
{
    // Tests the example at the end of chapter 5.4
    func testBookExample()
    {
        let expression = Binary(
            left: Unary(
                op: Token(type: .MINUS, lexeme: "-", literal: nil, line: 1),
                right: LiteralExp(value: .number(123))),
            op: Token(type: .STAR, lexeme: "*", literal: nil, line: 1),
            right: Grouping(expression: LiteralExp(value: .number(45.67))))

        let result = ASTPrinter().print(expression: expression)

        XCTAssertEqual(result, "(* (- 123.0) (group 45.67))")
    }
}