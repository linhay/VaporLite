//
//  File.swift
//
//
//  Created by linhey on 2023/4/6.
//

import Foundation
import CryptoSwift
import Vapor
import STJSON

public struct PK3API {
    
    struct Item: Codable {
        let credentials: String
    }
    
    struct Query: Content {
        let appId: String
        let sign: String
        let nonce: String
        let timestamp: Int
    }
    
    private let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    let uri: URI
    
    public let pkFilePath: String
    public let app_id: String
    
    public init(uri: URI,
                pkFilePath: String,
                app_id: String) {
        self.uri = uri
        self.pkFilePath = pkFilePath
        self.app_id = app_id
    }
    
}

public extension PK3API {
    
    func request(with app: Application) async throws -> JSON {
        let signKey = try self.readPKFile(pkFilePath)
        let nonce = (0...15).compactMap({ _ in charset.randomElement()?.description }).joined(separator: "")
        let timestamp = Int(Date().timeIntervalSince1970)
        let sign = sign(["appId": app_id,
                         "appSignKey": signKey,
                         "nonce": nonce,
                         "timestamp": timestamp])
        
        let query = Query(appId: app_id,
                          sign: sign ?? "",
                          nonce: nonce,
                          timestamp: timestamp)
        
        app.logger.debug("PK: 开始请求")
        let response = try await app.client.post(uri, beforeSend: { request in
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "application/x-www-form-urlencoded")
            request.headers = app.client.headers(merge: headers)
            try request.content.encode(query, as: .urlEncodedForm)
        })
        guard (200...299).contains(response.status.code) else {
            throw AxError.pk_network
        }
        app.logger.debug("PK: 数据返回")
        let item = try response.content.decode(OpenAPIResponsor<Item>.self).results.item
        app.logger.debug("PK: 开始解码")
        let decrypt = try decrypt(encrypted: item.credentials, projectKey: signKey)
        app.logger.debug("PK: 解码完成")
        return try JSON(data: decrypt)
    }
}

private extension PK3API {
    
}

private extension PK3API {
    
    func decrypt(encrypted: String, projectKey: String) throws -> Data {
        guard let data = Data(base64Encoded: encrypted) else {
            throw AxError.pk_decode
        }
        let key = projectKey.md5().bytes
        let cipher = try AES(key: Array(key[0..<16]),
                             blockMode: CBC(iv: Array(key[16..<32])),
                             padding: .pkcs5)
        return try Data(cipher.decrypt(data.bytes))
    }
    
    func sign(_ param: [String: Any]) -> String? {
        let toSignStr = param
            .sorted(by: { $0.key < $1.key })
            .map { (key, value) -> String in
                if let value = value as? Bool {
                    return value ? "\(key)=1" : "\(key)=0"
                }
                return "\(key)=\(value)"
            }
            .filter { !$0.isEmpty }
            .joined(separator: "&")
        return toSignStr.sha1()
    }
    
    func readPKFile(_ path: String) throws -> String {
        if FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            if let key = String(data: data, encoding: .utf8) {
                return key.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        throw AxError.pk_file_not_exist
    }
    
}


