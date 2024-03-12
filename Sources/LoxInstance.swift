class LoxInstance
{
    public init(class c: LoxClass)
    {
        self.lox_class = c
    }
    public func get_type_name() -> String { self.lox_class.name }

    private let lox_class: LoxClass
}
