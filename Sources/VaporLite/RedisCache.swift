//
//  File.swift
//  
//
//  Created by linhey on 2023/4/4.
//

import Redis
import Vapor

public protocol RedisCache {
    
    associatedtype Model: Codable
    var key: RedisKey { get }
    var redis: Request.Redis { get }
    
}

public extension RedisCache {
    
    func get() async throws -> Model? {
        try? await redis.get(key, asJSON: Model.self)
    }
    
    func set(_ model: Model?) async throws {
        try await redis.set(key, toJSON: model)
    }
    
    @discardableResult
    func delete() throws -> Int {
       try redis.delete([key]).wait()
    }
    
    
}
