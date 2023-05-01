//
//  GatewayProvisioningService.swift
//  Subconscious
//
//  Created by Ben Follington on 1/5/2023.
//

import Foundation
import os

struct ProvisionGatewayRequest: Codable {
    var invite_code: String
    var sphere: String
}

struct ProvisionGatewayErrorResponse: Codable {
    var error: String?
}

struct ProvisionGatewayResponse: Codable {
    var gateway_url: URL
    var gateway_did: Did
}

enum GatewayProvisioningServiceError: Error {
    case failedToProvisionGateway(String)
}

actor GatewayProvisioningService {
    private static let provisionGatewayEndpoint =
        Config.default.cloudCtlUrl.appending(
            path: "api/v0/public/provision_gateway"
        )
    
    private var jsonEncoder: JSONEncoder
    private var jsonDecoder: JSONDecoder
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "GatewayProvisioningService"
    )
    
    init() {
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }
    
    func provisionGateway(
        inviteCode: String,
        sphere: Did
    ) async throws -> ProvisionGatewayResponse {
        
        var request = URLRequest(url: Self.provisionGatewayEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ProvisionGatewayRequest(invite_code: inviteCode, sphere: sphere.description)
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GatewayProvisioningServiceError.failedToProvisionGateway(
                "Could not read response"
            )
        }
        
        guard response.success else {
            let responseBody = try self.jsonDecoder.decode(
                ProvisionGatewayErrorResponse.self,
                from: data
            )
            
            if let error = responseBody.error {
                throw GatewayProvisioningServiceError.failedToProvisionGateway(
                    "HTTP \(response.statusCode): \(error)"
                )
            } else {
                throw GatewayProvisioningServiceError.failedToProvisionGateway(
                    "Unexpected status code \(response.statusCode)"
                )
            }
        }
        
        return try self.jsonDecoder.decode(ProvisionGatewayResponse.self, from: data)
    }
}

extension HTTPURLResponse {
    var success: Bool {
        return (200 ... 299).contains(statusCode)
    }
}
