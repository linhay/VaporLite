//
//  File.swift
//
//
//  Created by linhey on 2023/4/20.
//

import Vapor
import Logging
import STJSON
import HTTPTypes
import HTTPTypesFoundation

public extension String {
    
    var isASCII: Bool {
        self.utf8.allSatisfy { $0 & 0x80 == 0 }
    }
    
}

public struct ClientLogQuery {
    
    public let logger: Logger
    public let userInfo: [String]
    public let level: Logger.Level
    
    public init(logger: Logger,
                level: Logger.Level = .debug,
                userInfo: [String] = []) {
        self.logger = logger
        self.level = level
        self.userInfo = userInfo
    }
    
}

class ClientLogPayload: Codable {
    var method: String?
    var url: String?
    var headers: [String]?
    var body: String?
    var response: String?
    var error: String?
}

public extension Client {
    
    func request(_ request: ClientRequest, log: ClientLogQuery) async throws -> ClientResponse {
        var request = request
        request.headers = headers(merge: request.headers)
        
        let logPayload = ClientLogPayload()
        let logTarck = LoggerMessageTrack(name: "client", id: log.userInfo.joined(separator: ","))
        logPayload.method = request.method.rawValue
        logPayload.url    = request.url.description.removingPercentEncoding ?? request.url.description
        logPayload.body   = request.body
            .flatMap(String.init(buffer:))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .prefix(200)
            .description
        request.body.flatMap(String.init(buffer:))?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "")
        
        let messagePayload = LoggerMessagePayload(track: logTarck, data: logPayload)
        defer { log.logger.log(level: log.level, .init(payload: messagePayload)) }
                
        do {
            let response = try await self.send(request).get()
            logTarck.status = .success
            logPayload.response = response.body
                .flatMap(String.init(buffer:))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "  ", with: " ")
                .prefix(200)
                .description
            
            return response
        } catch {
            logTarck.status = .failure
            logPayload.error = String.init(describing: error)
            throw error
        }
        
    }
    
    func headers(merge other: HTTPHeaders) -> HTTPHeaders {
        var headers = other
        if !other.contains(name: .userAgent) {
            headers.add(name: .userAgent, value: "vapor/aigc; apple/swift")
        }
        if !other.contains(name: .contentType) {
            headers.contentType = .json
        }
        return headers
    }
    
    func post<T>(_ url: URI,
                 headers: HTTPHeaders = [:],
                 content: T,
                 log: ClientLogQuery) async throws -> ClientResponse where T: Content {
        var request = ClientRequest(method: .POST, url: url, headers: self.headers(merge: headers))
        try request.content.encode(content)
        return try await self.request(request, log: log)
    }
    
    func get(_ url: URI,
             headers: HTTPHeaders = [:],
             log: ClientLogQuery,
             beforeSend: (inout ClientRequest) throws -> () = { _ in }) async throws -> ClientResponse {
        let request = ClientRequest(method: .GET, url: url, headers: self.headers(merge: headers))
        return try await self.request(request, log: log)
    }
    
}
