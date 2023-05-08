//
//  GatewayProvisioningService.swift
//  Subconscious
//
//  Created by Ben Follington on 1/5/2023.
//

import Foundation
import Combine
import os

struct ProvisionGatewayRequest: Codable {
    var invite_code: String
    var sphere: String
}

struct ProvisionGatewayErrorResponse: Codable {
    var error: String?
}

struct ProvisionGatewayResponse: Codable {
    var gateway_id: String
}

struct ProvisionGatewayStatusResponse: Codable {
    var status: String
    var did: String?
    var url: String?
}

enum GatewayProvisioningServiceError: Error {
    case failedToProvisionGateway(String)
    case failedToCheckGatewayProvisioningStatus(String)
    case gatewayIsNotReady
    case invalidStatusResponse(ProvisionGatewayStatusResponse)
}

extension GatewayProvisioningServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToProvisionGateway(let contentType):
            return String(
                localized: "Failed to provision gateway: \(contentType)",
                comment: "GatewayProvisioningService error description"
            )
        case .failedToCheckGatewayProvisioningStatus(let contentType):
            return String(
                localized: "Failed to check gateway status: \(contentType)",
                comment: "GatewayProvisioningService error description"
            )
        case .gatewayIsNotReady:
            return String(
                localized: "Gateway is not provisioned yet",
                comment: "GatewayProvisioningService error description"
            )
        case .invalidStatusResponse(let res):
            return String(
                localized: """
                    Invalid status response. \
                    (status=\(res.status), \
                    did=\(res.did ?? "<none>"), \
                    url=\(res.url ?? "<none>"))
                    """,
                comment: "GatewayProvisioningService error description"
            )
        }
    }
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
        inviteCode: InviteCode,
        sphere: Did
    ) async throws -> ProvisionGatewayResponse {
        
        var request = URLRequest(url: Self.provisionGatewayEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ProvisionGatewayRequest(
            invite_code: inviteCode.description,
            sphere: sphere.description
        )
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
        
        return try self.jsonDecoder.decode(
            ProvisionGatewayResponse.self,
            from: data
        )
    }
    
    private func checkGatewayProvisioningStatus(
        gatewayId: String
    ) async throws -> ProvisionGatewayStatusResponse {
        var request = URLRequest(url: Self.provisionGatewayEndpoint.appending(path: gatewayId))
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw GatewayProvisioningServiceError.failedToCheckGatewayProvisioningStatus(
                "Could not read response"
            )
        }
        
        guard response.success else {
            throw GatewayProvisioningServiceError.failedToCheckGatewayProvisioningStatus(
                "Unexpected status code \(response.statusCode)"
            )
        }
        
        return try self.jsonDecoder.decode(
            ProvisionGatewayStatusResponse.self,
            from: data
        )
    }
    
    func waitForGatewayProvisioning(
        gatewayId: String,
        maxAttempts: Int,
        attempts: Int = 0
    ) async throws -> URL? {
        do {
            let res = try await self.checkGatewayProvisioningStatus(gatewayId: gatewayId)
            
            guard res.status.lowercased() == "active" else {
                throw GatewayProvisioningServiceError.gatewayIsNotReady
            }
            
            // Validate response payload
            guard let did = res.did,
                  let _ = Did(did),
                  let url = res.url,
                  let url = URL(string: url) else {
                throw GatewayProvisioningServiceError.invalidStatusResponse(res)
            }
            
            return url
        } catch {
            let attempts = attempts + 1
            guard attempts < maxAttempts else {
                return nil
            }
            
            Self.logger.log("""
            Waiting to re-check provisioning status, \
            attempt \(attempts) of \(maxAttempts)
            """)
            
            sleep(UInt32(attempts))
            
            return try await self.waitForGatewayProvisioning(
                gatewayId: gatewayId,
                maxAttempts: maxAttempts,
                attempts: attempts
            )
        }
    }
    
    nonisolated func waitForGatewayProvisioningPublisher(
        gatewayId: String,
        maxAttempts: Int
    ) -> AnyPublisher<URL?, Error> {
        Future.detached {
            try await self.waitForGatewayProvisioning(
                gatewayId: gatewayId,
                maxAttempts: maxAttempts
            )
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func provisionGatewayPublisher(
        inviteCode: InviteCode,
        sphere: Did
    ) -> AnyPublisher<ProvisionGatewayResponse, Error> {
        Future.detached {
            try await self.provisionGateway(inviteCode: inviteCode, sphere: sphere)
        }
        .eraseToAnyPublisher()
    }
}

extension HTTPURLResponse {
    var success: Bool {
        return (200 ... 299).contains(statusCode)
    }
}
