//
//  CurrentLocationProvider.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI
import CoreLocation

class CurrentLocationProvider: NSObject, Observable, ObservableObject, CLLocationManagerDelegate {
    let resourceId = "current-location"
    let locationManager = CLLocationManager()
    
    @Published var clAuthStatus: CLAuthorizationStatus? = nil
    @Published var lastError: String? = nil
    
    override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    func checkAuthStatus() {
        self.clAuthStatus = locationManager.authorizationStatus
    }
    
    func setup() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func userRequestForLocation() {
        print("Requesting location...")
        locationManager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.clAuthStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Received location.")
        if let location = locations.first {
            ItemStore.shared.createItem(
                type: "location",
                attributes: [
                    "latitude": .number(location.coordinate.latitude),
                    "longitude": .number(location.coordinate.longitude)
                ],
                resource: nil // sent to user db since this is user-requested & should be synced to other devices
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error in location manager: \(error.localizedDescription)")
        self.lastError = error.localizedDescription
    }
}

struct CurrentLocationProviderSettings: View {
    @ObservedObject var locationProvider: CurrentLocationProvider
    
    func onAppear() {
        locationProvider.checkAuthStatus()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Current Location Provider").font(.title).padding(.bottom, 2)
                Text("Gets your device's current location.").padding(.bottom, 24)
                
                switch locationProvider.clAuthStatus ?? .notDetermined {
                case .notDetermined:
                    _RequestAccess(locationProvider: locationProvider)
                case .restricted:
                    Text("Access to current location restricted. In System Preferences > Privacy > Location Services > Workbench, ensure the toggle is on.")
                case .denied:
                    Text("Access to current location denied. In System Preferences > Privacy > Location Services > Workbench, ensure the toggle is on.")
                case .authorizedAlways:
                    _Settings(locationProvider: locationProvider)
                case .authorizedWhenInUse:
                    _Settings(locationProvider: locationProvider)
                case .authorized:
                    _Settings(locationProvider: locationProvider)
                @unknown default:
                    Text("Cannot determine calendar event access. Check System Preferences > Privacy > Location Services > Workbench.")
                }
            }
            .padding()
        }
        .onAppear(perform: onAppear)
    }
}

fileprivate struct _RequestAccess: View {
    let locationProvider: CurrentLocationProvider
    
    var body: some View {
        Button {
            locationProvider.setup()
        } label: {
            Text("Grant access to current location")
        }
    }
}

fileprivate struct _Settings: View {
    @ObservedObject var locationProvider: CurrentLocationProvider
    
    var body: some View {
        Text("Access granted.")
    }
}

//#Preview {
//    CurrentLocationProviderSettings()
//}
