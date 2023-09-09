import XCTest
@testable import slox

final class ASTPrinterTests: XCTestCase
{
    // Tests the example at the end of chapter 5.4
    func testBookExample()
    {
        // -123 * (45.67)
        let expression = Binary(
            left: Unary(
                op: Token(type: .MINUS, lexeme: "-", literal: nil, line: 1),
                right: LiteralExp(value: .number(123))),
            op: Token(type: .STAR, lexeme: "*", literal: nil, line: 1),
            right: Grouping(expression: LiteralExp(value: .number(45.67))))

        let result = ASTPrinter().print(expression: expression)

        XCTAssertEqual(result, "(* (- 123.0) (group 45.67))")
    }



    // Reverse Polish Notation (RPN). Exercise 5.3
    func testRPN()
    {
        // (1 + 2) * (4 - 3)
        let expression = Binary(
            left: Binary(
                left: LiteralExp(value: .number(1)),
                op: Token(type: .PLUS, lexeme: "+", literal: nil, line: 1),
                right: LiteralExp(value: .number(2))),
            op: Token(type: .STAR, lexeme: "*", literal: nil, line: 1),
            right: Binary(
                left: LiteralExp(value: .number(4)),
                op: Token(type: .MINUS, lexeme: "-", literal: nil, line: 1),
                right: LiteralExp(value: .number(3))))

        let result = ASTPrinterReversePolishNotation().print(expression: expression)

        XCTAssertEqual(result, "1.0 2.0 +  4.0 3.0 -  * ")
    }
}