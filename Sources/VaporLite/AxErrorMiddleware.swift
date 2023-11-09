//
//  File.swift
//  
//
//  Created by linhey on 2023/11/9.
//

import Foundation
import NIOCore
import NIOHTTP1
import Vapor

/// Captures all errors and transforms them into an internal server error HTTP response.
public struct AxErrorMiddleware: Middleware {
    
    /// Structure of `ErrorMiddleware` default response.
    internal struct ErrorResponse: Codable {
        var code: String
        /// Always `true` to indicate this is a non-typical JSON response.
        var error: Bool
        /// The reason for the error.
        var reason: String
    }

    /// Create a default `ErrorMiddleware`. Logs errors to a `Logger` based on `Environment`
    /// and converts `Error` to `Response` based on conformance to `AbortError` and `Debuggable`.
    ///
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    public static func `default`(environment: Environment) -> AxErrorMiddleware {
        return .init { req, error in
            // variables to determine
            let status: HTTPResponseStatus
            let reason: String
            let code: String
            let headers: HTTPHeaders

            // inspect the error type
            switch error {
            case let abort as AxError:
                code = abort.code
                reason = abort.reason
                status = abort.status
                headers = abort.headers
            case let abort as AbortError:
                // this is an abort error, we should use its status, reason, and headers
                code = ""
                reason = abort.reason
                status = abort.status
                headers = abort.headers
            default:
                // if not release mode, and error is debuggable, provide debug info
                // otherwise, deliver a generic 500 to avoid exposing any sensitive error info
                code = ""
                reason = environment.isRelease
                    ? "Something went wrong."
                    : String(describing: error)
                status = .internalServerError
                headers = [:]
            }
            
            // Report the error to logger.
            req.logger.report(error: error)
            
            // create a Response with appropriate status
            let response = Response(status: status, headers: headers)
            
            // attempt to serialize the error to json
            do {
                let errorResponse = ErrorResponse(code: code, error: true, reason: reason)
                response.body = try .init(data: JSONEncoder().encode(errorResponse), byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
            } catch {
                response.body = .init(string: "Oops: \(error)", byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
            }
            return response
        }
    }

    /// Error-handling closure.
    private let closure: @Sendable (Request, Error) -> (Response)

    /// Create a new `ErrorMiddleware`.
    ///
    /// - parameters:
    ///     - closure: Error-handling closure. Converts `Error` to `Response`.
    @preconcurrency public init(_ closure: @Sendable @escaping (Request, Error) -> (Response)) {
        self.closure = closure
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapErrorThrowing { error in
            return self.closure(request, error)
        }
    }
}
