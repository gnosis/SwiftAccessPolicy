//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class SQLiteDatabase: Database, Assertable {

    public let name: String
    public var exists: Bool { return false }
    public var url: URL!
    private let fileManager: FileManager
    private let sqlite: CSQLite3
    private let bundleIdentifier: String
    private var connections = [SQLiteConnection]()

    public enum Error: String, Hashable, LocalizedError {
        case applicationSupportDirNotFound
        case bundleIdentifierNotFound
        case databaseAlreadyExists
        case failedToCreateDatabase
        case databaseDoesNotExist
        case invalidSQLiteVersion
        case failedToOpenDatabase
        case databaseBusy
        case connectionIsNotOpened
        case invalidSQLStatement
        case attemptToExecuteFinalizedStatement
        case connectionIsAlreadyClosed
        case invalidConnection
        case statementWasAlreadyExecuted
        case runtimeError
        case invalidStatementState
        case transactionMustBeRolledBack
        case invalidStringBindingValue
        case failedToSetStatementParameter
        case statementParameterIndexOutOfRange
        case invalidStatementKeyValue
        case attemptToBindExecutedStatement
        case attemptToBindFinalizedStatement

        public var errorDescription: String? {
            return rawValue
        }
    }

    public init(name: String, fileManager: FileManager, sqlite: CSQLite3, bundleId: String) {
        self.name = name
        self.fileManager = fileManager
        self.sqlite = sqlite
        self.bundleIdentifier = bundleId
    }

    public func create() throws {
        try buildURL()
        try assertFalse(fileManager.fileExists(atPath: url.path), Error.databaseAlreadyExists)
        let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen]
        let didCreate = fileManager.createFile(atPath: url.path, contents: nil, attributes: attributes)
        if !didCreate {
            throw Error.failedToCreateDatabase
        }
    }

    public func connection() throws -> Connection {
        try buildURL()
        try assertTrue(fileManager.fileExists(atPath: url.path), Error.databaseDoesNotExist)
        try assertEqual(String(cString: sqlite.sqlite3_libversion()), sqlite.SQLITE_VERSION, Error.invalidSQLiteVersion)
        try assertEqual(String(cString: sqlite.sqlite3_sourceid()), sqlite.SQLITE_SOURCE_ID, Error.invalidSQLiteVersion)
        try assertEqual(sqlite.sqlite3_libversion_number(), sqlite.SQLITE_VERSION_NUMBER, Error.invalidSQLiteVersion)
        let connection = SQLiteConnection(sqlite: sqlite)
        try connection.open(url: url)
        connections.append(connection)
        return connection
    }

    public func close(_ connection: Connection) throws {
        guard let connection = connection as? SQLiteConnection else {
            throw SQLiteDatabase.Error.invalidConnection
        }
        try connection.close()
        if let index = connections.index(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }

    public func destroy() throws {
        try connections.forEach { try $0.close() }
        connections.removeAll()
        guard let url = url else { return }
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func buildURL() throws {
        if url != nil { return }
        let appSupportDir = try fileManager.url(for: .applicationSupportDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        try assertTrue(fileManager.fileExists(atPath: appSupportDir.path), Error.applicationSupportDirNotFound)
        let bundleDir = appSupportDir.appendingPathComponent(bundleIdentifier, isDirectory: true)
        if !fileManager.fileExists(atPath: bundleDir.path) {
            try fileManager.createDirectory(at: bundleDir, withIntermediateDirectories: false, attributes: nil)
        }
        self.url = bundleDir.appendingPathComponent(name).appendingPathExtension("db")
    }

}
