//
//  GatewayUrl.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 26/9/2023.
//

import Foundation

struct GatewayURL: Hashable, Equatable {
    var url: URL
    var absoluteString: String {
        url.absoluteString
    }
    
    var description: String {
        "GatewayURL<\(url.description)>"
    }
    
    init?(_ description: String) {
        guard let url = URL(string: description),
              url.isHTTP() else {
            return nil
        }
        
        self.url = url
    }
    
    init?(url: URL) {
        guard url.isHTTP() else {
            return nil
        }
        
        self.url = url
    }
}
