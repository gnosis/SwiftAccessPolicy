//
//  Created by Andrey Scherbovich on 19.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Assertable {

    /// Asserts that condition is true, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Condition to assert
    ///   - error: Error thrown if condition evaluates to false
    /// - Throws: Throws `error` when condition does not hold
    func assertArgument(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that `assertion` is nil, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Error thrown if expression is not nil
    /// - Throws: Throws `error` if assertion fails.
    func assertNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws

    /// Asserts that `assertion` is not nil, otherwise throws `error`
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Eror thrown if expression is nil
    /// - Throws: `error` if assertion fails.
    func assertNotNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws

    /// Asserts that `assertion` is true, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to be check if true
    ///   - error: Error thrown if expression is false
    /// - Throws: `error` if assertion fails.
    func assertTrue(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that `assertion` is false, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Error thrown if expression is true.
    /// - Throws: `error` if assertion fails
    func assertFalse(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that two arguments are equal, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - expression1: First expression to compare.
    ///   - expression2: Second expression to compare.
    ///   - error: Error thrown if expression1 is not equal to expression2.
    /// - Throws: `error` if assertion fails.
    func assertEqual<T>(_ expression1: @autoclosure () throws -> T,
                        _ expression2: @autoclosure () throws -> T,
                        _ error: Swift.Error) throws where T: Equatable

    /// Asserts that two arguments are not equal, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - expression1: First expression to compare.
    ///   - expression2: Second expression to compare.
    ///   - error: Error thrown if expression1 is equal to expression2.
    /// - Throws: `error` if assertion fails.
    func assertNotEqual<T>(_ expression1: @autoclosure () throws -> T,
                           _ expression2: @autoclosure () throws -> T,
                           _ error: Swift.Error) throws where T: Equatable
}

public extension Assertable {

    func assertArgument(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        if try !assertion() { throw error }
    }

    func assertNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws {
        if try assertion() != nil { throw error }
    }

    func assertNotNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws {
        if try assertion() == nil { throw error }
    }

    func assertTrue(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        if try !assertion() { throw error }
    }

    func assertFalse(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        try assertTrue(!assertion(), error)
    }

    func assertEqual<T>(_ expression1: @autoclosure () throws -> T,
                        _ expression2: @autoclosure () throws -> T,
                        _ error: Swift.Error) throws where T: Equatable {
        if try expression1() != expression2() { throw error }
    }

    func assertNotEqual<T>(_ expression1: @autoclosure () throws -> T,
                           _ expression2: @autoclosure () throws -> T,
                           _ error: Swift.Error) throws where T: Equatable {
        if try expression1() == expression2() { throw error }
    }

}


open class BaseID: Hashable, Assertable, CustomStringConvertible {

    /// Errors thrown if ID is invalid
    ///
    public enum Error: Swift.Error, Hashable {
        /// the ID provided to `BaseID.init(...)` method is invalid.
        case invalidID
    }

    public let id: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var description: String { return id }

    public static func ==(lhs: BaseID, rhs: BaseID) -> Bool {
        return lhs.id == rhs.id
    }

    /// Creates new identifier from string. By default takes random UUID string.
    ///
    /// - Parameter id: String to initialize the identifier with
    /// - Throws: Throws `Error.invalidID` if the `id` parameter is not 36 characters long.
    public required init(_ id: String = UUID().uuidString) {
        self.id = id
    }

}

open class IdentifiableEntity<T: Hashable>: Hashable, Assertable {

    public let id: T

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func ==(lhs: IdentifiableEntity<T>, rhs: IdentifiableEntity<T>) -> Bool {
        return lhs.id == rhs.id
    }

    /// Creates new instance with provided identifier
    ///
    /// - Parameter id: Identifier of the entitiy.
    public init(id: T) {
        self.id = id
    }

}

open class AbstractRegistry {

    private static var instance = AbstractRegistry()
    private var services = [String: Any]()

    /// Stores the implementation of `type` service in memory.
    ///
    /// You can later get the stored service with `service(...)` method.
    ///
    /// - Parameters:
    ///   - service: The instance implementing `type` protocol or class
    ///   - type: The class or protocol to store in registry.
    public class func put<T>(service: T, for type: T.Type) {
        instance.put(service: service, for: type)
    }

    /// Returns stored service of type `type`. Crashes if implementation for the service was not found.
    ///
    /// - Parameter type: Protocol or class registered before
    /// - Returns: instance in the registry.
    public class func service<T>(for type: T.Type) -> T {
        return instance.service(for: type)
    }

}

// MARK: - Instance Methods

private extension AbstractRegistry {

    func put<T>(service: T, for type: T.Type) {
        services[key(type)] = service
    }

    func service<T>(for type: T.Type) -> T {
        return services[key(type)]! as! T
    }

    func key(_ type: Any.Type) -> String {
        return String(describing: type)
    }

}

public extension String {

    var hasLetter: Bool {
        return rangeOfCharacter(from: CharacterSet.letters) != nil
    }

    var hasDecimalDigit: Bool {
        return rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }

    var hasNoTrippleChar: Bool {
        guard count > 2 else { return true }
        var previous = self.first!
        var sequenceLength = 1
        for c in dropFirst() {
            if c == previous {
                sequenceLength += 1
                if sequenceLength == 3 { return false }
            } else {
                previous = c
                sequenceLength = 1
            }
        }
        return true
    }

}

public extension Array {

    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

}

public extension SetAlgebra {

    func intersects(with other: Self) -> Bool {
        return !isDisjoint(with: other)
    }

}

public protocol Logger {

    /// Indicates a fatal error occurred. The application is supposed to be terminated soon.
    ///
    /// - Parameters:
    ///   - message: Fatal error message
    ///   - error: optional error that caused the fatal situation
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)

    /// Indicates that an error occurred. The application is supposed to still work.
    ///
    /// - Parameters:
    ///   - message: Error message
    ///   - error: optional error that caused the error situation
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)

    /// Indicates some important information.
    ///
    /// - Parameters:
    ///   - message: Info message
    ///   - error: optional error
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)

    /// Indicates a debug message.
    ///
    /// - Parameters:
    ///   - message: Debug message
    ///   - error: optional error
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func debug(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)

}

public extension Logger {

    func fatal(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.fatal(message, error: error, file: file, line: line, function: function)
    }

    func error(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.error(message, error: error, file: file, line: line, function: function)
    }

    func info(_ message: String,
              error: Error? = nil,
              file: StaticString = #file,
              line: UInt = #line,
              function: StaticString = #function) {
        self.info(message, error: error, file: file, line: line, function: function)
    }

    func debug(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.debug(message, error: error, file: file, line: line, function: function)
    }

}

public let LoggableErrorDescriptionKey = "LoggableErrorDescriptionKey"

/// Default implementation of utility to convert any `Swift.Error` to `NSError`
public protocol LoggableError: Error {

    /// Creates `NSError` and puts the `causedBy` error into `NSError.userInfo` dictionary.
    ///
    /// - Parameter causedBy: Underlying error
    /// - Returns: new NSError with `causedBy` underlying error inside.
    func nsError(causedBy: Error?) -> NSError
}

public extension LoggableError {

    func nsError(causedBy underlyingError: Error? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: localizedDescription,
                                       LoggableErrorDescriptionKey: String(describing: self)]
        if let error = underlyingError {
            userInfo[NSUnderlyingErrorKey] = error as NSError
        }
        return NSError(domain: String(describing: type(of: self)),
                       code: (self as NSError).code,
                       userInfo: userInfo)
    }

}

/// Loggable error that can be used in tests.
public enum TestLoggableError: LoggableError {
    /// Test error
    case error
}

public class MockLogger: Logger {

    public var fatalLogged = false
    public var errorLogged = false
    public var infoLogged = false
    public var debugLogged = false

    public var loggedError: Error?

    public init() {}

    public func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        fatalLogged = true
        loggedError = error
    }

    public func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        errorLogged = true
        loggedError = error
    }

    public func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        infoLogged = true
        loggedError = error
    }

    public func debug(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        debugLogged = true
        loggedError = error
    }

}
