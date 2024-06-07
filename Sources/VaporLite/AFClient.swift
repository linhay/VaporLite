//
//  File.swift
//  
//
//  Created by linhey on 2024/6/5.
//

import Foundation
import OpenAICore
import HTTPTypes
import HTTPTypesFoundation
import Alamofire
import Logging
import Vapor

public extension Application {
    
    var afClient: AFClient {
        if let client = storage.get(AFClientKey.self) {
            return client
        }
        let client = AFClient(logger: logger)
        storage.set(AFClientKey.self, to: client)
        return client
    }
    
}

struct AFClientKey: StorageKey {
    typealias Value = AFClient
}

public struct AFClient: LLMClientProtocol {

    public let logger: Logger?

    public func data(for request: HTTPRequest) async throws -> LLMResponse {
        guard let request = URLRequest(httpRequest: request) else {
            throw Abort(.internalServerError)
        }
        let response = try await AF.request(request).serializingData()
        guard let httpResponse = await response.response.response?.httpResponse else {
            throw Abort(.internalServerError)
        }
        return try await .init(data: response.value, response: httpResponse)
    }
    
    public func upload(for request: HTTPRequest, from bodyData: Data) async throws -> LLMResponse {
        guard let request = URLRequest(httpRequest: request) else {
            throw Abort(.internalServerError)
        }
        let response = try await AF.upload(bodyData, with: request).serializingData()
        guard let httpResponse = await response.response.response?.httpResponse else {
            throw Abort(.internalServerError)
        }
        return try await .init(data: response.value, response: httpResponse)
    }
    
    public func serverSendEvent(for request: HTTPRequest, from bodyData: Data, failure: (LLMResponse) async throws -> Void) async throws -> AsyncThrowingStream<Data, any Error> {
        fatalError()
    }
    
    public func upload(for request: HTTPRequest, from fields: [LLMMultipartField]) async throws -> LLMResponse {
        let response = AF.upload(multipartFormData: { form in
            
            for field in fields {
                switch field {
                case .string(name: let name, value: let value):
                    if let data = value.data(using: .utf8) {
                        form.append(data, withName: name)
                    }
                case .file(file: let file):
                    if let fileName = file.fileName, let mimeType = file.mimeType {
                        form.append(file.fileURL,
                                    withName: file.name,
                                    fileName: fileName,
                                    mimeType: mimeType)
                    } else {
                        form.append(file.fileURL, withName: file.name)
                    }
                }
            }
            
        }, with: URLRequest(httpRequest: request)!)
        .serializingData()
        logger?.info("upload: \(request.url?.absoluteString ?? "") \(fields)")
        return try await .init(data: response.value, response: response.response.response!.httpResponse!)
    }

}
