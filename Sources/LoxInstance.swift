class LoxInstance
{
    public init(class c: LoxClass)
    {
        self.lox_class = c
    }

    private let lox_class: LoxClass
}
