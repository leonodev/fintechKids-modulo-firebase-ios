//
//  FHKAnalytics.swift
//  FHKFirebase
//
//  Created by Fredy Leon on 28/2/26.
//

import FHKDomain
import FirebaseAnalytics

public final class FHKAnalytics: FHKAnalyticsProtocol {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(
            event.name,
            parameters: event.parameters
        )
    }
}

// Enums extender with its own screens and buttons
public enum Screens {}
public enum Buttons {}

public extension Screens {
    static let contentView = AnalyticsEvent.Screen(
        name: "ContentView",
        screenClass: "ContentView"
    )
}

public extension Buttons {
    static let btnSendTrack = AnalyticsEvent.Button(name: "BTN_DEMO_TRACK")
}
