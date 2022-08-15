//
//  MapModel.swift
//  AddressFinder
//
//  Created by Alexandre Talatinian on 15/08/2022.
//

import Foundation
import MapKit
import SwiftUI

struct Address: Codable {
    let data: [Datum]
}

struct Datum: Codable {
    let latitude, longitude: Double
    let name: String?
}

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class MapAPI: ObservableObject {
    private let BASE_URL = "http://api.positionstack.com/v1/"
    private let API_KEY = "88e02d44fe3c4f3f59191b7a6d65ce51"

    @Published var region: MKCoordinateRegion
    @Published var coordinates = []
    @Published var locations: [Location] = []
    
    init() {
        self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 45.46566784708076, longitude: 9.197416726636881), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
        
        self.locations.insert(Location(name: "Pin", coordinate: CLLocationCoordinate2D(latitude: 45.46566784708076, longitude: 9.197416726636881)), at: 0)
    }
    
    func getLocation(address: String, delta: Double) {
        let pAddress = address.replacingOccurrences(of: " ", with: "%20")
        let url_string = "\(BASE_URL)?access=key=\(API_KEY)&query=\(pAddress)"
        
        guard let url = URL(string: url_string) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print(error!.localizedDescription)
                return
            }
            
            guard let newCoordinates = try? JSONDecoder().decode(Address.self, from: data) else { return }
            
            if newCoordinates.data.isEmpty {
                print("Could not find the address...")
                return
            }
            
            DispatchQueue.main.async {
                let details = newCoordinates.data[0]
                let lon = details.longitude
                let lat = details.latitude
                let name = details.name
                
                self.coordinates = [lat, lon]
                self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))

                let new_location = Location(name: name ?? "Pin", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                self.locations.removeAll()
                self.locations.insert(new_location, at: 0)
                
                print("Location found successfully!")
            }
        }
        .resume()
    }
}
