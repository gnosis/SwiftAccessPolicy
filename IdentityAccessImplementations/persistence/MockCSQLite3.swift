//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import IdentityAccessImplementations
import SQLite3

class MockCSQLite3: CSQLite3 {

    var openedFilename: String?
    override var SQLITE_VERSION: String { return version }
    override var SQLITE_VERSION_NUMBER: Int32 { return number }
    override var SQLITE_SOURCE_ID: String { return sourceID }
    var version: String = ""
    var number: Int32 = 0
    var sourceID: String = ""


    var libversion_result: String = ""
    var sourceid_result: String = ""
    var libversion_number_result: Int32 = 0

    var open_result: Int32 = 0
    var open_pointer_result: OpaquePointer?
    override func sqlite3_open(_ filename: UnsafePointer<Int8>!,
                               _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> Int32 {
        if let fn = filename {
            openedFilename = String(cString: fn, encoding: .utf8)
        }
        ppDb.pointee = open_pointer_result
        return open_result
    }

    override func sqlite3_libversion_number() -> Int32 {
        return libversion_number_result
    }

    override func sqlite3_libversion() -> UnsafePointer<Int8>! {
        return libversion_result.withCString { ptr -> UnsafePointer<Int8> in ptr }

    }

    override func sqlite3_sourceid() -> UnsafePointer<Int8>! {
        return sourceid_result.withCString { ptr -> UnsafePointer<Int8> in ptr }
    }

    var close_pointer: OpaquePointer?
    var close_result: Int32 = 0
    override func sqlite3_close(_ db: OpaquePointer!) -> Int32 {
        close_pointer = db
        return close_result
    }

    var prepare_in_db: OpaquePointer?
    var prepare_in_zSql: UnsafePointer<Int8>?
    var prepare_in_zSql_string: String?
    var prepare_in_nByte: Int32?
    var prepare_result: Int32 = 0
    var prepare_out_ppStmt: OpaquePointer?
    var prepare_out_pzTail: UnsafePointer<Int8>?
    override func sqlite3_prepare_v2(_ db: OpaquePointer!,
                                     _ zSql: UnsafePointer<Int8>!,
                                     _ nByte: Int32,
                                     _ ppStmt: UnsafeMutablePointer<OpaquePointer?>!,
                                     _ pzTail: UnsafeMutablePointer<UnsafePointer<Int8>?>!) -> Int32 {
        prepare_in_db = db
        if let str = String(cString: zSql, encoding: .utf8) {
            prepare_in_zSql_string = str
        } else {
            prepare_in_zSql = zSql
        }
        prepare_in_nByte = nByte
        ppStmt.pointee = prepare_out_ppStmt
        pzTail.pointee = prepare_out_pzTail
        return prepare_result
    }

    var finalize_in_pStmt_list = [OpaquePointer]()
    var finalize_in_pStmt: OpaquePointer? { return finalize_in_pStmt_list.last }
    var finalize_result: Int32 = 0
    override func sqlite3_finalize(_ pStmt: OpaquePointer!) -> Int32 {
        finalize_in_pStmt_list.append(pStmt)
        return finalize_result
    }

    var get_autocommit_result: Int32 = 1
    var get_autocommit_in_db: OpaquePointer?
    override func sqlite3_get_autocommit(_ db: OpaquePointer!) -> Int32 {
        get_autocommit_in_db = db
        return get_autocommit_result
    }

    var step_results = [CSQLite3.SQLITE_DONE]
    var step_result_index = 0
    var step_in_pStmt: OpaquePointer?
    override func sqlite3_step(_ pStmt: OpaquePointer!) -> Int32 {
        step_in_pStmt = pStmt
        let result = step_results[step_result_index]
        step_result_index += 1
        return result
    }

    var column_count_result: Int32 = 0
    var column_count_in_pStmt: OpaquePointer?
    override func sqlite3_column_count(_ pStmt: OpaquePointer!) -> Int32 {
        column_count_in_pStmt = pStmt
        return column_count_result
    }

    var column_text_result: String?
    private var column_text_result_array: [Int8] = []
    override func sqlite3_column_text(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafePointer<UInt8>! {
        guard let result = column_text_result else { return nil }
        column_text_result_array = result.cString(using: .utf8)!
        return column_text_result_array.withUnsafeBytes { bufferPtr -> UnsafePointer<UInt8> in
            bufferPtr.baseAddress!.bindMemory(to: UInt8.self, capacity: bufferPtr.count)
        }
    }

    var column_bytes_result: Int32 = 0
    override func sqlite3_column_bytes(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Int32 {
        return column_bytes_result
    }

    var column_int64_result: SQLite3.sqlite3_int64 = 0
    override func sqlite3_column_int64(_ pStmt: OpaquePointer!, _ iCol: Int32) -> SQLite3.sqlite3_int64 {
        return column_int64_result
    }

    var column_double_result: Double = 0
    override func sqlite3_column_double(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Double {
        return column_double_result
    }

    var reset_result: Int32 = 0
    var reset_in_pStmt: OpaquePointer?
    override func sqlite3_reset(_ pStmt: OpaquePointer!) -> Int32 {
        reset_in_pStmt = pStmt
        return reset_result
    }
}
