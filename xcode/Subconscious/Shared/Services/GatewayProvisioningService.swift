//
//  GatewayProvisioningService.swift
//  Subconscious
//
//  Created by Ben Follington on 1/5/2023.
//

import Foundation
import Combine
import os

struct RedeemInviteCodeRequest: Codable {
    var invite_code: String
    var sphere: String
}

struct ErrorResponse: Codable {
    var error: String?
    var type: String?
}

struct RedeemInviteCodeResponse: Codable {
    var gateway_id: String
}

struct ProvisionGatewayStatusResponse: Codable {
    var status: String
    var did: String?
    var url: String?
}

enum GatewayProvisioningServiceError: Error {
    case failedToRedeemInviteCode(String)
    case failedToProvisionGateway(String)
    case failedToCheckGatewayProvisioningStatus(String)
    case gatewayIsNotReady
    case invalidStatusResponse(ProvisionGatewayStatusResponse)
}

extension GatewayProvisioningServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToRedeemInviteCode(let error):
            return String(
                localized: "Failed to redeem invite code: \(error)",
                comment: "GatewayProvisioningService error description"
            )
        case .failedToProvisionGateway(let error):
            return String(
                localized: "Failed to provision gateway: \(error)",
                comment: "GatewayProvisioningService error description"
            )
        case .failedToCheckGatewayProvisioningStatus(let error):
            return String(
                localized: "Failed to check gateway status: \(error)",
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
    
    func redeemInviteCode(
        inviteCode: InviteCode,
        sphere: Did
    ) async throws -> RedeemInviteCodeResponse {
        
        var request = URLRequest(url: Self.provisionGatewayEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RedeemInviteCodeRequest(
            invite_code: inviteCode.description,
            sphere: sphere.description
        )
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GatewayProvisioningServiceError.failedToRedeemInviteCode(
                "Could not read response"
            )
        }
        
        guard response.success else {
            let responseBody = try self.jsonDecoder.decode(
                ErrorResponse.self,
                from: data
            )
            
            if let error = responseBody.error {
                throw GatewayProvisioningServiceError.failedToRedeemInviteCode(
                    "HTTP \(response.statusCode): \(error)"
                )
            } else {
                throw GatewayProvisioningServiceError.failedToRedeemInviteCode(
                    "Unexpected status code \(response.statusCode)"
                )
            }
        }
        
        return try self.jsonDecoder.decode(
            RedeemInviteCodeResponse.self,
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
        gatewayId: String
    ) async throws -> GatewayURL? {
        let maxAttempts = 10 // 1+2+4+8+16+32+32+32+32+32 = 191 seconds
        return try await Func.retryWithBackoff(maxAttempts: maxAttempts) { attempts in
            Self.logger.log("""
            Check provisioning status, \
            attempt \(attempts) of \(maxAttempts)
            """)
            
            let res = try await self.checkGatewayProvisioningStatus(gatewayId: gatewayId)
            
            guard res.status.lowercased() == "active" else {
                throw GatewayProvisioningServiceError.gatewayIsNotReady
            }
            
            // Validate response payload
            guard let did = res.did,
                  let _ = Did(did),
                  let url = res.url,
                  let url = GatewayURL(url) else {
                throw GatewayProvisioningServiceError.invalidStatusResponse(res)
            }
            
            return url
        }
    }
    
    nonisolated func waitForGatewayProvisioningPublisher(
        gatewayId: String
    ) -> AnyPublisher<GatewayURL?, Error> {
        Future.detached {
            try await self.waitForGatewayProvisioning(
                gatewayId: gatewayId
            )
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func redeemInviteCodePublisher(
        inviteCode: InviteCode,
        sphere: Did
    ) -> AnyPublisher<RedeemInviteCodeResponse, Error> {
        Future.detached {
            try await self.redeemInviteCode(inviteCode: inviteCode, sphere: sphere)
        }
        .eraseToAnyPublisher()
    }
}

extension HTTPURLResponse {
    var success: Bool {
        return (200 ... 299).contains(statusCode)
    }
}
