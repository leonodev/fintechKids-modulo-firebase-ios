//
//  FHKAnalytics+Live.swift
//  FHKFirebase
//
//  Created by Fredy Leon on 28/2/26.
//
import FHKDomain
import FirebaseAnalytics
import FirebaseCrashlytics

public extension FHKAnalytics {
    
    static var live: Self {
        var analytics = Self()
        
        analytics.track = { event in
            switch event {
            case .error(let detail):
                // Analytics: globals statisticsKPIs)
                Analytics.logEvent("app_error", parameters: [
                    "error_type": detail.type
                ])
                
                let crashlytics = Crashlytics.crashlytics()
                crashlytics.setCustomValue(detail.type, forKey: "last_error_type")
                crashlytics.setCustomValue(detail.message, forKey: "last_error_json")
                
                crashlytics.log("Error: \(detail.type) - Details: \(detail.message)")
                
            default:
                // Eventos normales (ScrenView, TapButton, etc.)
                Analytics.logEvent(event.name, parameters: event.parameters)
            }
        }
        
        return analytics
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

