// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

enum AxLiteError: LocalizedError {
    case db_encode
    case db_decode
    case pk_network
    case pk_decode
    case pk_file_not_exist
}
