import Foundation

protocol ExpressionVisitor
{
	associatedtype R

	mutating func visit(_ assignment: Assignment) throws -> R
	mutating func visit(_ binary: Binary) throws -> R
	mutating func visit(_ call: Call) throws -> R
	mutating func visit(_ grouping: Grouping) throws -> R
	mutating func visit(_ literalexp: LiteralExp) throws -> R
	mutating func visit(_ logical: Logical) throws -> R
	mutating func visit(_ unary: Unary) throws -> R
	mutating func visit(_ ternary: Ternary) throws -> R
	mutating func visit(_ variable: Variable) throws -> R
	mutating func visit(_ funexpression: FunExpression) throws -> R
}



protocol Expression
{
	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R
	var uuid: UUID {get}
}



// TODO: Make assignment a Statement instead, like on Swift or Rust
struct Assignment: Expression
{
	let name: Token
	let value: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Binary: Expression
{
	let left: Expression
	let op: Token
	let right: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Call: Expression
{
	let callee: Expression
	let parenthesis: Token
	let arguments: [Expression]

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Grouping: Expression
{
	let expression: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct LiteralExp: Expression
{
	let value: Literal?

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Logical: Expression
{
	let left: Expression
	let op: Token
	let right: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Unary: Expression
{
	let op: Token
	let right: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Ternary: Expression
{
	let condition: Expression
	let then_branch: Expression
	let else_branch: Expression

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Variable: Expression
{
	let name: Token

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct FunExpression: Expression
{
	let parameters: [Token]
	let body: Block

	func accept<R, V: ExpressionVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}
