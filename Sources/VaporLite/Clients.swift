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

public extension HTTPFields {
    
    init(_ fields: HTTPHeaders) {
        var headers = HTTPFields()
        for field in fields {
            if let name = HTTPField.Name(field.name) {
                headers[name] = field.value
            }
        }
        self = headers
    }
    
}

public extension HTTPField {
    
    var isoLatin1Value: String {
        if self.value.isASCII {
            return self.value
        } else {
            return self.withUnsafeBytesOfValue { buffer in
                let scalars = buffer.lazy.map { UnicodeScalar(UInt32($0))! }
                var string = ""
                string.unicodeScalars.append(contentsOf: scalars)
                return string
            }
        }
    }
    
    
}

public extension HTTPHeaders {
    
    init(_ fields: HTTPFields) {
        var combinedFields = [HTTPField.Name: String](minimumCapacity: fields.count)
        for field in fields {
            if let existingValue = combinedFields[field.name] {
                let separator = field.name == .cookie ? "; " : ", "
                combinedFields[field.name] = "\(existingValue)\(separator)\(field.isoLatin1Value)"
            } else {
                combinedFields[field.name] = field.isoLatin1Value
            }
        }
        var headers = HTTPHeaders()
        for (name, value) in combinedFields {
            headers.add(name: name.rawName, value: value)
        }
        self = headers
    }
    
}

public extension ClientRequest {
    
    init?(_ httpRequest: HTTPRequest) {
        guard let url = httpRequest.url else {
            return nil
        }
        var request = ClientRequest(url: .init(string: url.absoluteString))
        request.method  = .init(rawValue: httpRequest.method.rawValue)
        request.headers = .init(httpRequest.headerFields)
        self = request
    }
    
}

public extension HTTPResponse {
    
    init(_ response: ClientResponse) {
        self.init(status: .init(code: Int(response.status.code),
                                reasonPhrase: response.status.reasonPhrase),
                  headerFields: .init(response.headers))
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

public extension Client {
    
    func request(_ request: ClientRequest, log: ClientLogQuery) async throws -> ClientResponse {
        var request = request
        request.headers = headers(merge: request.headers)
        
        var messages = ["Client", request.method.rawValue, request.url.description.removingPercentEncoding ?? request.url.description]
        defer { log.logger.log(level: log.level, .init(stringLiteral: messages.joined(separator: ", "))) }
        messages.append("headers: [\(request.headers.filter({ $0.name.lowercased() != "authorization" }).description)]")
        messages.append("userInfo: [\(log.userInfo.joined(separator: ","))]")
        messages.append("query: \(body(by: request.body))")
        
        do {
            let response = try await self.send(request).get()
            messages.append("body: \(self.body(by: response.body))")
            return response
        } catch {
            messages.append(String.init(describing: error))
            throw error
        }
        
    }
    
    func headers(merge other: HTTPHeaders) -> HTTPHeaders {
        var headers = other
        if !other.contains(name: .userAgent) {
            headers.add(name: .userAgent, value: "vapor/aigc; apple/swift")
        }
        if !other.contains(name: .contentType) {
            headers.add(name: .contentType, value: "application/json; charset=utf-8")
        }
        return headers
    }
    
    func body(by body: ByteBuffer?) -> String {
        string(by: try? body?.string)
    }
    
    func string(by string: String?) -> String {
        string?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "") ?? ""
    }
    
    func post(_ url: URI,
              headers: HTTPHeaders = [:],
              content: JSON,
              userInfo: [String] = [],
              logger: Logger,
              logLevel: Logger.Level = .debug) async throws -> ClientResponse {
        let request = ClientRequest(method: .POST, url: url,
                                    headers: self.headers(merge: headers),
                                    body: try .init(data: content.rawData()))
        return try await self.request(request,
                                      log: .init(logger: logger, level: logLevel, userInfo: userInfo))
    }
    
    func post<T>(_ url: URI,
                 headers: HTTPHeaders = [:],
                 content: T,
                 userInfo: [String] = [],
                 logger: Logger,
                 logLevel: Logger.Level = .debug) async throws -> ClientResponse where T: Content {
        var request = ClientRequest(method: .POST, url: url,
                                    headers: self.headers(merge: headers))
        try request.content.encode(content)
        return try await self.request(request,
                                      log: .init(logger: logger, level: logLevel, userInfo: userInfo))
    }
    
    func get(_ url: URI,
             headers: HTTPHeaders = [:],
             userInfo: [String] = [],
             logger: Logger,
             logLevel: Logger.Level = .debug,
             beforeSend: (inout ClientRequest) throws -> () = { _ in }) async throws -> ClientResponse {
        let request = ClientRequest(method: .GET, url: url,
                                    headers: self.headers(merge: headers))
        return try await self.request(request,
                                      log: .init(logger: logger, level: logLevel, userInfo: userInfo))
    }
    
}
