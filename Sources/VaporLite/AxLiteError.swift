// The Swift Programming Language
// https://docs.swift.org/swift-book

import Vapor

public struct AxError: AbortError {
    
    public let status: HTTPResponseStatus
    public let reason: String
    public let code: String
    
    public init(_ reason: String,
                status: HTTPResponseStatus = .badRequest,
                code: String = "") {
        self.status = status
        self.reason = reason
        self.code = code
    }
    
}


public extension AxError {
    
    static let database_encode   = AxError("database encode error")
    static let database_decode   = AxError("database decode error")
    static let pk_network        = AxError("pk network error")
    static let pk_decode         = AxError("pk decode")
    static let pk_file_not_exist = AxError("pk file not exist")
    
}
