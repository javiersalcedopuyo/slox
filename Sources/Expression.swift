protocol Visitor
{
	associatedtype R

	func visit(_ binary: Binary) -> R
	func visit(_ grouping: Grouping) -> R
	func visit(_ literalexp: LiteralExp) -> R
	func visit(_ unary: Unary) -> R
	func visit(_ ternary: Ternary) -> R
}



protocol Expression
{
	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R
}



struct Binary: Expression
{
	let left: Expression
	let op: Token
	let right: Expression

	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }
}



struct Grouping: Expression
{
	let expression: Expression

	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }
}



struct LiteralExp: Expression
{
	let value: Literal?

	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }
}



struct Unary: Expression
{
	let op: Token
	let right: Expression

	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }
}



struct Ternary: Expression
{
	let condition: 		Expression
	let then_branch: 	Expression
	let else_branch: 	Expression

	func accept<R, V: Visitor>(visitor: V) -> R where V.R == R { visitor.visit(self) }
}