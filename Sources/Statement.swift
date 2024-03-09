import Foundation

protocol StatementVisitor
{
	associatedtype R

	mutating func visit(_ block: Block) throws -> R
	mutating func visit(_ expressionstatement: ExpressionStatement) throws -> R
	mutating func visit(_ conditionalstatement: ConditionalStatement) throws -> R
	mutating func visit(_ funstatement: FunStatement) throws -> R
	mutating func visit(_ whilestatement: WhileStatement) throws -> R
	mutating func visit(_ breakstatement: BreakStatement) throws -> R
	mutating func visit(_ print: Print) throws -> R
	mutating func visit(_ varstatement: VarStatement) throws -> R
	mutating func visit(_ returnstatment: ReturnStatment) throws -> R
}



protocol Statement
{
	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R
	var uuid: UUID {get}
}



struct Block: Statement
{
	let statements: [Statement]

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct ExpressionStatement: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct ConditionalStatement: Statement
{
	let condition: Expression
	let then_branch: Statement
	let else_branch: Statement?

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct FunStatement: Statement
{
	let name: Token
	let function: FunExpression

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct WhileStatement: Statement
{
	let condition: Expression
	let body: Statement

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct BreakStatement: Statement
{
	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct Print: Statement
{
	let expression: Expression

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct VarStatement: Statement
{
	let name: Token
	let initializer: Expression?

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}



struct ReturnStatment: Statement
{
	let keyword: Token
	let value: Expression?

	func accept<R, V: StatementVisitor>(visitor: inout V) throws -> R where V.R == R { try visitor.visit(self) }
	let uuid = UUID()
}
