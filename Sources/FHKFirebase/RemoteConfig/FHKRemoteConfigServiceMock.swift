//
//  FirebaseRemoteConfigMock.swift
//  FHKFirebase
//
//  Created by fleon  on 3/7/26.
//

import FHKDomain
import Foundation

@MainActor
public final class FHKRemoteConfigServiceMock: FHKRemoteConfigManagerProtocol {
    
    public var enabledLanguages: [String] {
        return []
    }
    
    public var menuHomeItems: [MenuHomeItem] {
        return [
            MenuHomeItem(id: 0,
                         name: "payments",
                         icon: "payments-icon",
                         label_localized_key: "key_payments_title",
                         active: true)
        ]
    }
    public func fetchConfig() async throws {
        
    }
    
    public func getCachedTimeExpiration() async -> Int {
        return 1
    }
}
