protocol ExpressionVisitor
{
	associatedtype R

	func visit(_ binary: Binary) throws -> R
	func visit(_ grouping: Grouping) throws -> R
	func visit(_ literalexp: LiteralExp) throws -> R
	func visit(_ unary: Unary) throws -> R
	func visit(_ ternary: Ternary) throws -> R
	func visit(_ variable: Variable) throws -> R
}



protocol Expression
{
	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R
}



struct Binary: Expression
{
	let left: Expression
	let op: Token
	let right: Expression

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Grouping: Expression
{
	let expression: Expression

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct LiteralExp: Expression
{
	let value: Literal?

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Unary: Expression
{
	let op: Token
	let right: Expression

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Ternary: Expression
{
	let condition: Expression
	let then_branch: Expression
	let else_branch: Expression

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Variable: Expression
{
	let name: Token

	func accept<R, V: ExpressionVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}
