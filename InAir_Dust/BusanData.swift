//
//  BusanData.swift
//  InAir_Dust
//
//  Created by D7703_04 on 2018. 12. 4..
//  Copyright © 2018년 D7703_04. All rights reserved.
//

import Foundation
import MapKit

class BusanData: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var pm10: String?
    var co2: String?
    var no2: String?
    
   
    
   
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, pm10: String, co2: String, no2: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.pm10 = pm10
        self.co2 = co2
        self.no2 = no2
       
       
    }
}
