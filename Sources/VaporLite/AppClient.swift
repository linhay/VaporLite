//
//  File.swift
//  
//
//  Created by linhey on 2024/4/15.
//

import OpenAICore
import Vapor
import HTTPTypes
import VaporLite
import AsyncHTTPClient

public extension Application {
    
    var appClient: AppClient {
        if let client = storage.get(NormalClient.self) {
            return client
        }
        let configuration: HTTPClient.Configuration = .init()
        let client = AppClient(configuration: configuration)
        storage.set(NormalClient.self, to: client) { client in
            client.shutdown(self)
        }
        return client
    }
    
}

struct NormalClient: StorageKey {
    typealias Value = AppClient
}


public struct AppClient: OAIClientProtocol, LifecycleHandler {
        
    public let client: HTTPClient

    public init(configuration: HTTPClient.Configuration) {
        self.client = .init(configuration: configuration)
    }
    
    public func shutdown(_ application: Application) {
        try? client.syncShutdown()
    }
    
    public func data(for request: HTTPRequest) async throws -> OAIClientResponse {
        guard let request = try HTTPClient.Request(request) else {
            throw Abort(.internalServerError)
        }
        let result = try await client.execute(request: request).get()
        return try response(of: result)
    }
    
    public func upload(for request: HTTPRequest, from bodyData: Data) async throws -> OAIClientResponse {
        guard var request = try HTTPClient.Request(request) else {
            throw Abort(.internalServerError)
        }
        request.body = .data(bodyData)
        let result = try await client.execute(request: request).get()
        return try response(of: result)
    }
    
    public func serverSendEvent(for request: HTTPRequest, from bodyData: Data, failure: (OAIClientResponse) async throws -> Void) async throws -> AsyncThrowingStream<Data, Error> {
        guard let request = HTTPClientRequest(request, body: .init(data: bodyData)) else {
            throw Abort(.internalServerError)
        }
        let response = try await client.execute(request, timeout: .minutes(10))
        if response.status != .ok {
            var data = Data()
            for try await buffer in response.body {
                print(String.init(buffer: buffer))
                data.append(.init(buffer: buffer))
            }
            try await failure(.init(data: data, response: response.httpResponse))
        }

        let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()
        Task {
            do {
                for try await buffer in response.body {
                    print(String.init(buffer: buffer))
                    continuation.yield(.init(buffer: buffer))
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return stream
    }

    public func vaild(of result: HTTPClientResponse) throws {
        if result.status.code < 200 || result.status.code > 299 {
            throw Abort(.init(statusCode: Int(result.status.code)))
        }
    }
    
    public func response(of result: HTTPClient.Response) throws -> OAIClientResponse {
        if result.status.code < 200 || result.status.code > 299 {
            throw Abort(.init(statusCode: Int(result.status.code)))
        } else if let bytesView = result.body.flatMap({ Data.init(buffer: $0) }) {
            return .init(data: bytesView, response: result.httpResponse)
        } else {
            return .init(data: .init(), response: result.httpResponse)
        }
    }
    
}
