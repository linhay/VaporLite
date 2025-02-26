//
//  File.swift
//  
//
//  Created by linhey on 2023/4/4.
//

import Redis
import Vapor

public extension Request.Redis {
    
    func get<Model: Codable>(of key: String) async throws -> Model? {
        try? await get(.init(stringLiteral: key), asJSON: Model.self)
    }
    
    func set<Model: Codable>(of key: String, _ model: Model?) async throws {
        try await set(.init(stringLiteral: key), toJSON: model)
    }
    
    @discardableResult
    func delete(_ keys: [String]) async throws -> Int {
        try await delete(keys.compactMap(RedisKey.init(rawValue:))).get()
    }
    
    @discardableResult
    func delete(_ keys: String) async throws -> Int {
        try await delete([keys])
    }
    
}
