//
//  FHKAnalyticsService.swift
//  FHKFirebase
//
//  Created by Fredy Leon on 28/2/26.
//
import FHKDomain
import FirebaseAnalytics
import FirebaseCrashlytics

public final class FHKAnalyticsService: FHKAnalyticsProtocol {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        switch event {
        case .error(let detail):
            //  Analytics: For statistics (KPIs)
            Analytics.logEvent("app_error", parameters: [
                "error_type": detail.type
            ])
            
            // Crashlytics: For DEBURGING
            let crashlytics = Crashlytics.crashlytics()
            crashlytics.setCustomValue(detail.type, forKey: "last_error_type")
            crashlytics.setCustomValue(detail.message, forKey: "last_error_json")
            
            crashlytics.log("Error: \(detail.type) - Details: \(detail.message)")
        default:
            // Normal events (ScrenView, TapButton)
            Analytics.logEvent(event.name, parameters: event.parameters)
        }
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

