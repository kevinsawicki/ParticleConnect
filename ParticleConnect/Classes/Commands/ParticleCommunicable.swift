//
//  ParticleCommunicable.swift
//  ParticleConnect
//
//  Created by Mike on 12/1/17.
//

public protocol ParticleCommunicable {
    static var command: String { get }
    associatedtype ResponseType
    static func parse(_ json: [AnyHashable: Any]) -> ResponseType?
}
