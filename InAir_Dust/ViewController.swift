//
//  ViewController.swift
//  InAir_Dust
//
//  Created by D7703_04 on 2018. 12. 4..
//  Copyright © 2018년 D7703_04. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, XMLParserDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var stepper: UIStepper!
    
    var locationManager = CLLocationManager()
    
    //    var annotationPM10: BusanDataPM10?
    //    var annotationPM25: BusanDataPM25?
    
    //    var annotationsPM10: Array = [BusanDataPM10]()
    //    var annotationsPM25: Array = [BusanDataPM25]()
    
    var annotation: BusanData?
    var annotations: Array = [BusanData]()
    
    
    var item:[String:String] = [:]  // item[key] => value
    var items:[[String:String]] = []
    var currentElement = ""
    
    var address: String?
    var lat: String?
    var long: String?
    var loc: String?
    var dLat: Double?
    var dLong: Double?
   
    
    var tPM10: String?
   
    
    var tco2: String?

    
    var pm10Val: String?  // value test
    var pm25Val: String?
    
    // 1시간 마다 호출위해 타이머 객체 생성
    var timer = Timer()
    var currentTime: String?
    
    //    var label: UILabel?
    
    @IBOutlet weak var segControlBtn: UISegmentedControl!
    
    // 광복동, 초량동
    let addrs:[String:[String]] = [
        "201111" : ["중구 남포동 구덕로 지하 12", "35.098041", "129.035033", "남포역 대합실"],
        "201191" : ["부산진구 부전동 260-22", "35.1583462", "129.0582437"," 1호선 대합실"],
        "201193" : ["부산진구 부전2동 중앙대로 720-1", "35.1570747", "129.0583408", "서면역 1호선 승강장"],
        "202191" : ["부산진구 부전동 257-63", "35.1570747", "129.0583408"," 2호선 대합실"],
        "202192" : ["부산진구 부전1동 가야대로 789", "35.1579012", "129.0569016", "2호선 승강장"],
        "202271" : ["괘법동", "35.1625397", "128.985913", "사상역 대합실"],
        "203011" : ["수영구 수영로 576", "35.167273", "129.115664", "한국환경공단"],
        "203051" : ["연산동", "35.1865484", "129.0780535", "연산연 대합실"],
        "203091" : ["온천3동", "35.2054534", "129.065853", "미남역 대합실"],
        "203131" : ["부산광역시 덕천2동", "35.2113369", "129.0036468", "덕천역 대합실"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "부산 미세먼지 지도"
        // Do any additional setup after loading the view, typically from a nib.
        
        // 사용자 현재 위치 트랙킹
        locationManager.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.startUpdatingLocation()
        
        // 사용자 현재 위치, 캠파스 표시
        myMapView.showsUserLocation = true
        myMapView.showsCompass = true
        
        myParse()
        timer = Timer.scheduledTimer(timeInterval: 60*60, target: self, selector: #selector(myParse), userInfo: nil, repeats: true)
        // Map
        myMapView.delegate = self
        //  초기 맵 region 설정
        
        //zoomToRegion()
        mapDisplay()
    }
    
    // Segment Control function
    @IBAction func segControlPressed(_ sender: Any) {
        if segControlBtn.selectedSegmentIndex == 0 {
            print("Seg o pressed")
            // zoomToRegion()
            
            // 기존 데이터 삭제
            //            annotations.removeAll()
            removeAllAnnotations()
            
            mapDisplay()
            
        } else if segControlBtn.selectedSegmentIndex == 1 {
            print("Seg 1 pressed")
            //zoomToRegion()
            //            annotations.removeAll()
            removeAllAnnotations()
            
            mapDisplay()
        }
        print(annotations.count, self.myMapView.annotations.count)
    }
    
    func mapDisplay() {
        
        for item in items {
            let dSite = item["areaIndex"]
            print("dSite = \(items.count) \(String(describing: dSite))")
            
            // 추가 데이터 처리
            for (key, value) in addrs {
                if key == dSite {
                    address = value[0]
                    lat = value[1]
                    long = value[2]
                    loc = value[3]
                    dLat = Double(lat!)
                    dLong = Double(long!)
                }
            }
            
            // 파싱 데이터 처리
            let dPM10 = item["pm10"]
            let dco2 = item["co2"]
           
            
            annotation = BusanData(coordinate: CLLocationCoordinate2D(latitude: dLat!, longitude: dLong!),
                                   title: dSite!, subtitle: loc!,
                                   pm10: dPM10!,co2: dco2!)
            
            annotations.append(annotation!)
        }
        myMapView.showAnnotations(annotations, animated: true)
        //        myMapView.addAnnotations(annotations)
        
    }
    
    func removeAllAnnotations() {
        for annotation in self.myMapView.annotations {
            self.myMapView.removeAnnotation(annotation)
        }
    }
    
    
    @objc func myParse() {
        // XML Parsing
        let key = "cLHR7K%2BU8sG3j6B0ULITYNuZPyKB1PYG2USwW3dYmJ5bzi%2FCc3CTAPzYOlnenW%2BUBUlbjpFtnF%2F6JIiRe3Ygmw%3D%3D"
        let strURL = "http://opendata.busan.go.kr/openapi/service/IndoorAirQuality/getIndoorAirQualityByStation?ServiceKey=\(key)&numOfRows=21"
        
        if let url = URL(string: strURL) {
            if let parser = XMLParser(contentsOf: url) {
                parser.delegate = self
                
                                                          if (parser.parse()) {
                    print("parsing success")
                    
                    // 파싱이 끝난시간 시간 측정
                    let date: Date = Date()
                    let dayTimePeriodFormat = DateFormatter()
                    dayTimePeriodFormat.dateFormat = "YYYY/MM/dd HH시"
                    currentTime = dayTimePeriodFormat.string(from: date)
                    for item in items {
                        print("Station = \(item["site"]!) item pm10 = \(item["pm10"]!)")
                    }
                    
                } else {
                    print("parsing fail")
                }
            } else {
                print("url error")
            }
        }
        
    }
    
    // XML Parsing Delegate 메소드
    // XMLParseDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElement = elementName
        
        // tag 이름이 elements이거나 item이면 초기화
        if elementName == "items" {
            items = []
        } else if elementName == "item" {
            item = [:]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        //        print("data = \(data)")
        if !data.isEmpty {
            item[currentElement] = data
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            items.append(item)
        }
    }
    
    func zoomToRegion() {
        let location = CLLocationCoordinate2D(latitude: 35.180100, longitude: 129.081017)
        let span = MKCoordinateSpan(latitudeDelta: 0.27, longitudeDelta: 0.27)
        let region = MKCoordinateRegion(center: location, span: span)
        myMapView.setRegion(region, animated: true)
    }
    
    @IBAction func changeToOriginLocation(_ sender: Any) {
        
        let currnetLoc: CLLocation = locationManager.location!
        let location = CLLocationCoordinate2D(latitude: currnetLoc.coordinate.latitude, longitude: currnetLoc.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.20, longitudeDelta: 0.20)
        let region = MKCoordinateRegion(center: location, span: span)
        myMapView.setRegion(region, animated: true)
        
    }
    
    func changeStepperLocation(sLat: Double, sLong: Double) {
        
        let currnetLoc: CLLocation = locationManager.location!
        let location = CLLocationCoordinate2D(latitude: currnetLoc.coordinate.latitude, longitude: currnetLoc.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: sLat, longitudeDelta: sLong)
        let region = MKCoordinateRegion(center: location, span: span)
        myMapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func stepperPressed(_ sender: Any) {
        let stepVal = stepper.value
        switch stepVal {
        case 1:
            print("Tesp 1")
            changeStepperLocation(sLat: 0.28, sLong: 0.28)
        case 2:
            print("Tesp 2")
            changeStepperLocation(sLat: 0.20, sLong: 0.20)
        case 3:
            print("Tesp 3")
            changeStepperLocation(sLat: 0.12, sLong: 0.12)
        case 4:
            print("Tesp 4")
            changeStepperLocation(sLat: 0.04, sLong: 0.04)
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let seg_index = segControlBtn.selectedSegmentIndex
        
        if seg_index == 0 {  // PM10
            let reuseID = "pm10"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
            var iPm10Val = 0
            
            if annotation is MKUserLocation {
                return nil
            }
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationView!.canShowCallout = true
                annotationView?.animatesWhenAdded = true
                
                let castBusanData = annotationView!.annotation as? BusanData
                pm10Val = castBusanData?.pm10
                
                //let pm10Val = castBusanData?.pm10
                let pm10Station = castBusanData?.title
                //let pm10ValCai = castBusanData?.pm10Cai
                print("\(String(describing: pm10Station)) pm10 val = \(String(describing: pm10Val))")
                
                annotationView?.glyphTintColor = UIColor.lightGray
                annotationView?.glyphText = pm10Val
                
                if pm10Val != nil {
                    iPm10Val = Int(pm10Val!)!
                } else {
                    // dumy value
                    //iPm10Val = 0
                }
                
                switch iPm10Val {
                case 0..<31:
                    annotationView?.markerTintColor = UIColor.blue // 좋음
                case 31..<81:
                    annotationView?.markerTintColor = UIColor.green // 보통
                case 81..<151:
                    annotationView?.markerTintColor = UIColor.yellow
                case 151..<600:
                    annotationView?.markerTintColor = UIColor.red // 매우나쁨
                default : break
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = btn
            return annotationView
            
        } else if seg_index == 1 {  // PM25
            let reuseID = "pm25"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
            var iPm25Val = 0
            
            if annotation is MKUserLocation {
                return nil
            }
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationView!.canShowCallout = true
                annotationView?.animatesWhenAdded = true
                
                let castBusanData = annotationView!.annotation as? BusanData
                pm25Val = castBusanData?.co2
                
                iPm25Val = Int(pm25Val!)!
                print("iPm25Val = \(iPm25Val)")
                
                annotationView?.glyphTintColor = UIColor.lightGray
                //                annotationView?.glyphText = String(iPm25Val)
                
                annotationView?.glyphText = pm25Val
                
                switch iPm25Val {
                case 0..<16:
                    annotationView?.markerTintColor = UIColor.blue // 좋음
                case 16..<36:
                    annotationView?.markerTintColor = UIColor.green // 보통
                case 36..<75:
                    annotationView?.markerTintColor = UIColor.yellow // 나쁨
                case 76..<500:
                    annotationView?.markerTintColor = UIColor.red // 매우나쁨
                default : break
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = btn
            return annotationView
        } else {
            
            return annotation as! MKAnnotationView
        }
    }
    
   
    // rightCalloutAccessoryView를 눌렀을때 호출되는 delegate method
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let viewAnno = view.annotation as! BusanData // 데이터 클래스로 형변환(Down Cast)
        
        if segControlBtn.selectedSegmentIndex == 0 {
            let vPM10 = viewAnno.pm10
            let vStation = viewAnno.title
            
            print("vPm10 = \(String(describing: vPM10))")
            let dPM10: Int = Int(vPM10!)!
            
            switch Int(dPM10) {
            case 0..<31:
                tPM10 = "좋음" // 좋음
            case 31..<81:
                tPM10 = "보통"// 보통
            case 81..<151:
                tPM10 = "나쁨" // 나쁨
            case 76..<500:
                tPM10 = "매우나쁨" // 매우나쁨
            default : break
            }
            
            let mTitle = "미세먼지(PM 10) : \(tPM10!)(\(vPM10!) ug/m3)"
            let ac = UIAlertController(title: vStation! + " 대기질 측정소", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "측정시간 : " + currentTime! , style: .default, handler: nil))
            ac.addAction(UIAlertAction(title: mTitle, style: .default, handler: nil))
          
            ac.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: nil))
            self.present(ac, animated: true, completion: nil)
            
        } else if segControlBtn.selectedSegmentIndex == 1 {
            let vPM25 = viewAnno.co2
            let vStation = viewAnno.title
            //let vPM25Cai = viewAnno.pm10Cai
            
            print("PM25 = \(String(describing: vPM25))")
            
            let dPM25: Int = Int(vPM25!)!
            
            switch Int(dPM25) {
            case 0..<31:
                tco2 = "좋음" // 좋음
            case 31..<81:
                tco2 = "보통"// 보통
            case 81..<151:
                tco2 = "나쁨" // 나쁨
            case 76..<500:
                tco2 = "매우나쁨" // 매우나쁨
            default : break
            }
            
            //            switch vPM25Cai {
            //                case "1": mPM25Cai = "좋음"
            //                case "2": mPM25Cai = "보통"
            //                case "3": mPM25Cai = "나쁨"
            //                case "4": mPM25Cai = "아주나쁨"
            //                default : mPM25Cai = "오류"
            //            }
            
            let mTitle = "미세먼지(PM 2.5) : \(tco2!)(\(vPM25!) ug/m3)"
            let ac = UIAlertController(title: vStation! + " 대기질 측정소", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "측정시간 : " + currentTime! , style: .default, handler: nil))
            ac.addAction(UIAlertAction(title: mTitle, style: .default, handler: nil))
           
            ac.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: nil))
            self.present(ac, animated: true, completion: nil)
            
        }
    }
}


