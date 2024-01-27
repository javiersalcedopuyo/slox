protocol StatementVisitor
{
	associatedtype R

	mutating func visit(_ block: Block) throws -> R
	mutating func visit(_ expressionstatement: ExpressionStatement) throws -> R
	mutating func visit(_ conditionalstatement: ConditionalStatement) throws -> R
	mutating func visit(_ whilestatement: WhileStatement) throws -> R
	mutating func visit(_ breakstatement: BreakStatement) throws -> R
	mutating func visit(_ print: Print) throws -> R
	mutating func visit(_ varstatement: VarStatement) throws -> R
}



protocol Statement
{
	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R
}



struct Block: Statement
{
	let statements: [Statement]

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct ExpressionStatement: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct ConditionalStatement: Statement
{
	let condition: Expression
	let then_branch: Statement
	let else_branch: Statement?

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct WhileStatement: Statement
{
	let condition: Expression
	let body: Statement

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct BreakStatement: Statement
{
	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct Print: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}



struct VarStatement: Statement
{
	let name: Token
	let initializer: Expression?

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
}
