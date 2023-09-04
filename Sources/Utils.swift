// I don't want to use the `isNumber` property because I only want basic single digits
func is_digit(_ c: Character) -> Bool { c >= "0" && c <= "9" }

func is_letter(_ c: Character) -> Bool { (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") }

func is_alphanumeric(_ c: Character) -> Bool { is_letter(c) || is_digit(c) }