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
    
    var appClient: VaporClient {
        if let client = storage.get(VaporClientKey.self) {
            return client
        }
        let client = VaporClient(client: self.client, logger: logger)
        storage.set(VaporClientKey.self, to: client)
        return client
    }
    
}

struct VaporClientKey: StorageKey {
    typealias Value = VaporClient
}

public struct VaporClient: LLMClientProtocol {
    
    public let client: Vapor.Client
    public var timeoutInterval: Double = 60 * 5
    public let logger: Logger?

    public init(client: Vapor.Client, logger: Logger? = nil) {
        self.logger = logger
        self.client = client
    }
    
    public func data(for request: HTTPRequest, progress: RequestProgress?) async throws -> LLMResponse {
        guard let request = ClientRequest.init(request, body: nil) else {
            throw Abort(.internalServerError)
        }
        let result = try await execute(request, logger: logger)
        return try await response(of: result)
    }
    
    public func upload(for request: HTTPRequest, from fields: [LLMMultipartField]) async throws -> LLMResponse {
        try await AFClient(logger: logger, timeoutInterval: timeoutInterval).upload(for: request, from: fields)
    }
    
    public func upload(for request: HTTPRequest, from bodyData: Data) async throws -> LLMResponse {
        guard let request = ClientRequest.init(request, body: .init(data: bodyData)) else {
            throw Abort(.internalServerError)
        }
        let result = try await execute(request, logger: logger)
        return try await response(of: result)
    }
    
    public func serverSendEvent(for request: HTTPRequest, from bodyData: Data, failure: (LLMResponse) async throws -> Void) async throws -> AsyncThrowingStream<Data, Error> {
        assertionFailure("use NIOClient")
        return .makeStream().stream
    }

    public func execute(_ request: ClientRequest, logger: Logger?) async throws -> ClientResponse {
        var request = request
        if request.headers.contentType == nil {
            request.headers.contentType = .json
        }
        if request.headers[.userAgent].isEmpty {
            request.headers.add(name: .userAgent, value: "vapor/aigc; apple/swift")
        }
        let prefix = "[\(request.method.rawValue)] \(request.url.description)"
        do {
            let response = try await client.send(request)
            if let logger = logger {
                let str = response.body
                    .flatMap({ String.init(buffer: $0) })?
                    .replacingOccurrences(of: "\n", with: "")
                    .split(separator: " ", omittingEmptySubsequences: true)
                    .reduce("", { $0 + " " + $1 })
                logger.info("\(prefix)\n\(str ?? "")")
            }
            return response
        } catch {
            logger?.error("\(prefix)\n\(String.init(describing: error))")
            throw error
        }
    }
    
    public func vaild(of result: ClientResponse) throws {
        if result.httpResponse.status.kind != .successful {
            throw Abort(.init(statusCode: Int(result.status.code)))
        }
    }
    
    public func response(of response: ClientResponse) async throws -> LLMResponse {
        if response.status.code < 200 || response.status.code > 299 {
            throw Abort(.init(statusCode: Int(response.status.code)))
        } else {
            let data = response.body.flatMap({ Data.init(buffer:$0) }) ?? .init()
            return .init(data: data, response: response.httpResponse)
        }
    }
    
}
