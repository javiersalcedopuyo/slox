import XCTest
@testable import slox

final class FunctionalityTests: XCTestCase
{
    func test_1()
    {
        let lox = Lox()
        let test_path = "Tests/test_1.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_class_methods()
    {
        let lox = Lox()
        let test_path = "Tests/test_class_methods.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_closures()
    {
        let lox = Lox()
        let test_path = "Tests/test_closures.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_creating_class_instances()
    {
        let lox = Lox()
        let test_path = "Tests/test_creating_class_instances.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_function_declarations()
    {
        let lox = Lox()
        let test_path = "Tests/test_function_declarations.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_recursive_fibonacci()
    {
        let lox = Lox()
        let test_path = "Tests/test_recursive_fibonacci.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_resolver_errors()
    {
        let lox = Lox()
        let test_path = "Tests/test_resolver_errors.slox"
        lox.run(file: test_path)
        XCTAssert( Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_set_get_properties()
    {
        let lox = Lox()
        let test_path = "Tests/test_set_get_properties.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_for_loops()
    {
        let lox = Lox()
        let test_path = "Tests/test_for_loops_9_5.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_this()
    {
        let lox = Lox()
        let test_path = "Tests/test_this.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_invalid_use_of_this()
    {
        let lox = Lox()
        let test_path = "Tests/test_invalid_use_of_this.slox"
        lox.run(file: test_path)
        XCTAssert( Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_exercise_9_3()
    {
        let lox = Lox()
        let test_path = "Tests/test_exercise_9_3.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_exercise_10_2()
    {
        let lox = Lox()
        let test_path = "Tests/test_exercise_10_2.slox"
        lox.run(file: test_path)
        XCTAssert( !Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }


    func test_exercise_11_3()
    {
        let lox = Lox()
        let test_path = "Tests/test_exercise_11_3.slox"
        lox.run(file: test_path)
        XCTAssert( Lox.had_error )
        XCTAssert( !Lox.had_runtime_error )
    }
}
