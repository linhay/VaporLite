//
//  File.swift
//  
//
//  Created by linhey on 2024/4/15.
//

import OpenAICore
import Vapor
import HTTPTypes
import AsyncHTTPClient

public extension Application {
    
    var nioClient: NIOClient {
        if let client = storage.get(NIOClientKey.self) {
            return client
        }
        let configuration: HTTPClient.Configuration = .init()
        let client = NIOClient(configuration: configuration, logger: logger)
        storage.set(NIOClientKey.self, to: client) { client in
            client.shutdown(self)
        }
        return client
    }
    
}

struct NIOClientKey: StorageKey {
    typealias Value = NIOClient
}

public struct NIOClient: LLMClientProtocol, LifecycleHandler {
        
    public let client: HTTPClient
    public let logger: Logger?

    public init(configuration: HTTPClient.Configuration, logger: Logger? = nil) {
        var configuration = configuration
        configuration.connectionPool.concurrentHTTP1ConnectionsPerHostSoftLimit = 1024
        self.logger = logger
        self.client = .init(configuration: configuration)
    }
    
    public func shutdown(_ application: Application) {
        try? client.syncShutdown()
    }
    
    public func data(for request: HTTPRequest) async throws -> LLMResponse {
        guard let request = HTTPClientRequest.init(request, body: nil) else {
            throw Abort(.internalServerError)
        }
        let result = try await execute(request)
        return try await response(of: result)
    }
    
    public func upload(for request: HTTPRequest, from bodyData: Data) async throws -> LLMResponse {
        guard let request = HTTPClientRequest.init(request, body: .init(data: bodyData)) else {
            throw Abort(.internalServerError)
        }
        let result = try await execute(request)
        return try await response(of: result)
    }
    
    public func serverSendEvent(for request: HTTPRequest, from bodyData: Data, failure: (LLMResponse) async throws -> Void) async throws -> AsyncThrowingStream<Data, Error> {
        guard let request = HTTPClientRequest(request, body: .init(data: bodyData)) else {
            throw Abort(.internalServerError)
        }
        let response = try await execute(request)
        if response.status != .ok {
            var data = Data()
            for try await buffer in response.body {
                data.append(.init(buffer: buffer))
            }
            try await failure(.init(data: data, response: response.httpResponse))
        }

        let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()
        Task {
            do {
                for try await buffer in response.body {
                    continuation.yield(.init(buffer: buffer))
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return stream
    }

    public func execute(_ request: HTTPClientRequest) async throws -> HTTPClientResponse {
        var request = request
        if request.headers.contentType == nil {
            request.headers.contentType = .json
        }
        if request.headers[.userAgent].isEmpty {
            request.headers.add(name: .userAgent, value: "vapor/aigc; apple/swift")
        }
        do {
            return try await client.execute(request, timeout: .minutes(10))
        } catch {
            let prefix = "[\(request.method.rawValue)] \(request.url.description)"
            logger?.error("\(prefix)\n\(String.init(describing: error))")
            throw error
        }
    }
    
    public func vaild(of result: HTTPClientResponse) throws {
        if result.status.code < 200 || result.status.code > 299 {
            throw Abort(.init(statusCode: Int(result.status.code)))
        }
    }
    
    public func response(of response: HTTPClientResponse) async throws -> LLMResponse {
        if response.status.code < 200 || response.status.code > 299 {
            throw Abort(.init(statusCode: Int(response.status.code)))
        } else {
            var data = Data()
            for try await buffer in response.body {
                data.append(.init(buffer: buffer))
            }
            return .init(data: data, response: response.httpResponse)
        }
    }
    
}
