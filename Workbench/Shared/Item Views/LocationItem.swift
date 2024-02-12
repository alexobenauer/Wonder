//
//  LocationItem.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(LocationItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color(red: 97/255, green: 22/255, blue: 120/255)
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        nil
    }
}

fileprivate struct LocationItemView: View {
    let itemId: String
    
    @State private var locationName: String? = nil
    
    var body: some View {
        ItemStoreValue {
            (
                ItemStore.shared.fetchFacts(itemId: itemId, attribute: "latitude").first?.typedValue?.numberValue,
                ItemStore.shared.fetchFacts(itemId: itemId, attribute: "longitude").first?.typedValue?.numberValue
            )
        } content: { result -> AnyView in
            if let latitude = result.0, let longitude = result.1 {
                return AnyView(MapAtLocationView(latitude: latitude, longitude: longitude))
            }
            
            return AnyView(EmptyView())
        }
    }
}

fileprivate class LocationName: ObservableObject {
    init(latitude: Double, longitude: Double) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { place, error in
            if let locality = place?.first?.locality, let country = place?.first?.country {
                self.value = "\(locality), \(country)"
            }
            else if let locality = place?.first?.locality {
                self.value = locality
            }
            else if let country = place?.first?.country {
                self.value = country
            }
        }
    }
    
    @Published var value: String? = nil
}

fileprivate struct MapAtLocationView: View {
    init(latitude: Double, longitude: Double) {
        self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        self._locationName = StateObject(wrappedValue: LocationName(latitude: latitude, longitude: longitude))
    }
    
    @StateObject private var locationName: LocationName
    @State private var region: MKCoordinateRegion
    
    var body: some View {
        VStack(alignment: .leading) {
            if let locationName = locationName.value {
                Text(locationName)
                    .font(.system(size: 10, design: .monospaced))
            }
            
            Map(coordinateRegion: $region)
                .frame(width: 400, height: 300)
        }
    }
}

#Preview {
    LocationItemView(itemId: "")
}
