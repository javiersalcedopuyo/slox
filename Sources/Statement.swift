protocol StatementVisitor
{
	associatedtype R

	func visit(_ expressionstatement: ExpressionStatement) throws -> R
	func visit(_ print: Print) throws -> R
	mutating func visit(_ varstatement: VarStatement) throws -> R
}



protocol Statement
{
	func accept<R, V: StatementVisitor>(visitor: V) throws -> R where V.R == R
}



struct ExpressionStatement: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Print: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct VarStatement: Statement
{
	let name: Token
	let initializer: Expression?

	func accept<R, V: StatementVisitor>(visitor: V) throws -> R where V.R == R { try visitor.visit(self) }
}
