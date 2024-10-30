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
        let client = AFClient(logger: logger, timeoutInterval: 60 * 5)
        storage.set(AFClientKey.self, to: client)
        return client
    }
    
}

struct AFClientKey: StorageKey {
    typealias Value = AFClient
}

public class AFClient: LLMClientProtocol {
    
    public let logger: Logger?
    public var timeoutInterval: Double
    private let session: Alamofire.Session
    
    public init(session: Alamofire.Session = .default,
                logger: Logger?,
                timeoutInterval: Double) {
        self.logger = logger
        self.session = session
        self.session.sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
        self.timeoutInterval = timeoutInterval
    }
    
    func request(of request: HTTPRequest) throws -> URLRequest {
        guard var request = URLRequest(httpRequest: request) else {
            throw Abort(.internalServerError)
        }
        request.timeoutInterval = timeoutInterval
        return request
    }
    
    public func data(for request: HTTPRequest, progress: RequestProgress?) async throws -> LLMResponse {
        let response = try await session.request(self.request(of: request))
            .validate()
            .downloadProgress { unit in
                progress?(unit.totalUnitCount, unit.completedUnitCount)
            }
            .serializingData()
        guard let httpResponse = await response.response.response?.httpResponse else {
            throw Abort(.internalServerError)
        }
        let data = try await response.value
        return try await .init(data: data, response: httpResponse)
    }
    
    public func upload(for request: HTTPRequest, from bodyData: Data) async throws -> LLMResponse {
        let response = try await session.upload(bodyData, with: self.request(of: request))
            .validate()
            .serializingData()
        guard let httpResponse = await response.response.response?.httpResponse else {
            throw Abort(.internalServerError)
        }
        return try await .init(data: response.value, response: httpResponse)
    }
    
    public func upload(for request: HTTPRequest, fromFile fileURL: URL, progress: @escaping (_ total: Int64, _ completed: Int64) -> Void?) async throws -> LLMResponse {
        let response = try await session.upload(fileURL, with: self.request(of: request))
            .validate()
            .uploadProgress { unit in
                progress(unit.completedUnitCount, unit.completedUnitCount)
            }
            .serializingData()
        return try await .init(data: response.value, response: response.response.response!.httpResponse!)
    }
    
    public func serverSendEvent(for request: HTTPRequest, from bodyData: Data, failure: (LLMResponse) async throws -> Void) async throws -> AsyncThrowingStream<Data, any Error> {
        fatalError()
    }
    
    public func upload(for request: HTTPRequest, from fields: [LLMMultipartField]) async throws -> LLMResponse {
        let response = try session.upload(multipartFormData: { form in
            
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
            
        }, with: self.request(of: request)).serializingData()
        logger?.info("upload: \(request.url?.absoluteString ?? "") \(fields)")
        return try await .init(data: response.value, response: response.response.response!.httpResponse!)
    }
    
}
