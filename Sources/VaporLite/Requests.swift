//
//  File.swift
//
//
//  Created by linhey on 2024/4/8.
//

import Foundation
import Vapor
import Logging
import STJSON
import HTTPTypes
import HTTPTypesFoundation
import AsyncHTTPClient

public extension String {
    
    var isASCII: Bool {
        self.utf8.allSatisfy { $0 & 0x80 == 0 }
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
    
    var httpFields: HTTPFields {
        var headers = HTTPFields()
        for field in self {
            if let name = HTTPField.Name(field.name) {
                headers[name] = field.value
            }
        }
        return headers
    }
    
}

public extension ClientResponse {
    
    init?(_ httpResponse: HTTPResponse, body: ByteBuffer?) {
        self.init(status: .init(statusCode: httpResponse.status.code),
                  headers: .init(httpResponse.headerFields),
                  body: body)
    }
    
    var httpResponse: HTTPResponse {
        .init(status: .init(code: Int(status.code),
                            reasonPhrase: status.reasonPhrase),
              headerFields: headers.httpFields)
    }
    
}

public extension HTTPClient.Response {
    
    init?(_ httpResponse: HTTPResponse, host: String, version: HTTPVersion, body: ByteBuffer?) {
        self.init(host: host,
                  status: .init(statusCode: httpResponse.status.code),
                  version: version,
                  headers: .init(httpResponse.headerFields),
                  body: body)
    }
    
    var httpResponse: HTTPResponse {
        .init(status: .init(code: Int(status.code),
                            reasonPhrase: status.reasonPhrase),
              headerFields: headers.httpFields)
    }
    
}

public extension HTTPClientRequest {
    
    init?(_ httpRequest: HTTPRequest, body: ByteBuffer?) {
        guard let url = httpRequest.url else {
            return nil
        }
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method  = .init(rawValue: httpRequest.method.rawValue)
        request.headers = .init(httpRequest.headerFields)
        request.body    = body.flatMap(Body.bytes) ?? .none
        self = request
    }
    
    var httpRequest: HTTPRequest {
        let url = URL(string: url)
        return HTTPRequest(method: .init(rawValue: method.rawValue) ?? .get,
                           scheme: url?.scheme,
                           authority: [url?.host, url?.port?.description]
            .compactMap({ $0 })
            .joined(separator: ":"),
                           path: url?.path,
                           headerFields: headers.httpFields)
    }
    
}

public extension HTTPClientResponse {
    
    init(_ httpResponse: HTTPResponse,
         version: HTTPVersion = .http1_1,
         body: ByteBuffer? = .init()) {
        self.init(version: version,
                  status: .init(statusCode: httpResponse.status.code),
                  headers: .init(httpResponse.headerFields),
                  body: body.flatMap(Body.bytes) ?? .init())
    }
    
    var httpResponse: HTTPResponse {
        .init(status: .init(code: Int(status.code),
                            reasonPhrase: status.reasonPhrase),
              headerFields: headers.httpFields)
    }
    
}

public extension ClientRequest {
    
    init?(_ httpRequest: HTTPRequest, body: ByteBuffer?) {
        guard let url = httpRequest.url else {
            return nil
        }
        let httpRequest = httpRequest
        var request = ClientRequest(url: .init(string: url.absoluteString), body: body)
        request.method  = .init(rawValue: httpRequest.method.rawValue)
        request.headers = .init(httpRequest.headerFields)
        self = request
    }
    
    var httpRequest: HTTPRequest {
        HTTPRequest(method: .init(rawValue: method.rawValue) ?? .get,
                    scheme: url.scheme,
                    authority: [url.host, url.port?.description].compactMap({ $0 }).joined(separator: ":"),
                    path: [url.path, url.query].compactMap({ $0 }).joined(separator: "?"),
                    headerFields: headers.httpFields)
    }
    
}

public extension HTTPClient.Request {
    
    init?(_ httpRequest: HTTPRequest) throws {
        guard let url = httpRequest.url else {
            return nil
        }
        try self.init(url: url,
                      method: .init(rawValue: httpRequest.method.rawValue),
                      headers: .init(httpRequest.headerFields))
    }
    
    var httpRequest: HTTPRequest {
        HTTPRequest(method: .init(rawValue: method.rawValue) ?? .get,
                    scheme: url.scheme,
                    authority: [url.host, url.port?.description].compactMap({ $0 }).joined(separator: ":"),
                    path: url.path,
                    headerFields: headers.httpFields)
    }
    
}
