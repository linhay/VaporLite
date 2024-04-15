//
//  File.swift
//  
//
//  Created by linhey on 2024/4/12.
//

import Foundation
import Vapor
import AnyCodable

extension AnyCodable: Content {}

extension AnyCodable: AsyncResponseEncodable {
    
    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response()
        try response.content.encode(self)
        return response
    }
    
}

extension AsyncStream: AsyncResponseEncodable where Element == ByteBuffer {
  
    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response(status: .ok)
        let body = Response.Body(stream: { writer in
            Task {
                for try await element in self {
                    _ = writer.write(.buffer(element))
                }
                _ = writer.write(.end)
            }
        })
        response.headers.contentType = .init(type: "text", subType: "event-stream", parameters: ["charset": "utf8"])
        response.body = body
        return response
    }
    
}

extension AsyncThrowingStream: AsyncResponseEncodable where Element == ByteBuffer {
  
    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response(status: .ok)
        let body = Response.Body(stream: { writer in
            Task {
                for try await element in self {
                    _ = writer.write(.buffer(element))
                }
                _ = writer.write(.end)
            }
        })
        response.headers.contentType = .init(type: "text", subType: "event-stream", parameters: ["charset": "utf8"])
        response.body = body
        return response
    }
}

extension AsyncThrowingStream where Element == Data {
  
    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response(status: .ok)
        let body = Response.Body(stream: { writer in
            Task {
                for try await element in self {
                    _ = writer.write(.buffer(.init(data: element)))
                }
                _ = writer.write(.end)
            }
        })
        response.headers.contentType = .init(type: "text", subType: "event-stream", parameters: ["charset": "utf8"])
        response.body = body
        return response
    }
}
