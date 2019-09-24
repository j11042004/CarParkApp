//
//  ViewController.swift
//  WhereIsMyCar
//
//  Created by Uran on 2017/11/6.
//  Copyright © 2017年 Uran. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Photos
class ViewController: UIViewController {

    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var nowLocationBtn: UIButton!
    
    var locationManager : CLLocationManager?
    var origoLocation : CLLocationCoordinate2D?
    var startLocation : CLLocationCoordinate2D?
    var goalLocation : CLLocationCoordinate2D?
    var userDefault = UserDefaults.standard
    
    var saveArray = [[String:Any]]()
    var savedBool = false
    var begainNavigation = false {
        didSet{
            self.mapNavitionBtn.title = self.begainNavigation ? "導航中" : "導航至車子"
        }
    }
    var saveBarBtn: UIBarButtonItem!
    var deleteBarBtn : UIBarButtonItem!
    var mapNavitionBtn : UIBarButtonItem!
    
    let cameraImage = UIImage(named: "nowLocation.png")
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        //  Prepare locationManager
        // 位置精確度，最精準得是BestForNavigation
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // 這個app使用的種類：行人模式
        locationManager?.activityType = CLActivityType.fitness
        
        mainMapView.delegate = self
        locationManager?.delegate = self
        // 判斷權限是否有授權
        askUserAuthorization()
        // 設定 BarButton Item
        self.saveBarBtn = UIBarButtonItem(title: "儲存停車紀錄", style: .done, target: self, action: #selector(self.saveCarLocationAction(_:)))
        self.deleteBarBtn = UIBarButtonItem(title: "刪除停車紀錄", style: .done, target: self, action: #selector(clearParkInfoBarBtnAction(_:)))
        self.mapNavitionBtn = UIBarButtonItem(title: "導航至車子", style: .done, target: self, action: #selector(mapNavigationBarBtnAction(_:)))
        
        // 設定 使用者現在位址 button 的背景圖片，並把按鈕設為圓形
        nowLocationBtn.setBackgroundImage(UIImage(named: "nowLocation.png"), for: UIControl.State.normal)
        nowLocationBtn.layer.cornerRadius = 25
        nowLocationBtn.clipsToBounds = true
    }
    override func viewDidAppear(_ animated: Bool) {
        changeBarButton()
    }
// MARK:- UI Action Function
    func changeBarButton(){
        savedBool = getUserSavedInformation()
        // 判斷是否有存資料
        if !savedBool{
            self.navigationItem.rightBarButtonItems = [saveBarBtn]
            return
        }
        let barbuttons : [UIBarButtonItem] = [deleteBarBtn,mapNavitionBtn]
        self.navigationItem.rightBarButtonItems = barbuttons
    }
    
    @IBAction func nowLocationBtnAction(_ sender: Any) {
        moveToUserNowLocation()
    }
    @objc func saveCarLocationAction(_ sender: Any) {
        self.begainNavigation = false
        addNewAnnotationAlert()
        self.mainMapView.removeOverlays(self.mainMapView.overlays)
    }
    @objc func clearParkInfoBarBtnAction(_ sender: Any) {
        self.begainNavigation = false
        clearParkInformation()
        self.mainMapView.removeOverlays(self.mainMapView.overlays)
    }
    @objc func mapNavigationBarBtnAction(_ sender: Any) {
        self.begainNavigation = !self.begainNavigation
        if self.begainNavigation {
            navigationToUserCar()
        }else {
            self.mainMapView.removeOverlays(self.mainMapView.overlays)
        }
    }
//MARK:- Normal Function
    // 首次使用 向使用者詢問定位自身位置權限
    func askUserAuthorization(){
        // 首次使用 向使用者詢問定位自身位置權限
        if CLLocationManager.authorizationStatus() == .notDetermined {
            // 取得定位服務授權
            locationManager?.requestWhenInUseAuthorization()
            // 開始定位自身位置
            locationManager?.startUpdatingLocation()
        }
            // 使用者已經拒絕定位自身位置權限
        else if CLLocationManager.authorizationStatus() == .denied {
            // 提示可至[設定]中開啟權限
            let alertController = UIAlertController( title: "定位權限已關閉", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler:nil)
            alertController.addAction(okAction)
            self.present( alertController, animated: true, completion: nil)
        }
            // 使用者已經同意定位自身位置權限
        else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            // 開始定位自身位置
            locationManager?.startUpdatingLocation()
        }
    }
    /// Move to user's location
    func moveToUserNowLocation() {
        // 將所在位址放大
        guard let coordinate = locationManager?.location?.coordinate else {
            return
        }
        var region  = MKCoordinateRegion()
        region.center = coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        // 移到現在的所在位置
        mainMapView.setRegion(region, animated: true)
    }
    /// The add address alert Function
    func addNewAnnotationAlert(){
        // Get now user's location
        guard let nowCarLocation = self.locationManager?.location?.coordinate else {
            return
        }
        // Get now time's string
        let dateString = GetDate().getNowTimeString()
        // Build the add alert
        let pinAlert = UIAlertController(title: "停車紀錄", message: "請輸入備註", preferredStyle: UIAlertController.Style.alert)
        // add a textField on the alert
        pinAlert.addTextField { (insertText) in
            insertText.borderStyle = UITextField.BorderStyle.roundedRect
            insertText.placeholder = "備註"
            insertText.text = ""
        }
        // Add only Note action
        let onlyNote = UIAlertAction.init(title: "註記", style: .default) { (action) in
            let textField = pinAlert.textFields?[0]
            guard let note = textField?.text else {
                // Add the new Pin on the map without note
                self.addNewAnnotationOnMap(coordinate: nowCarLocation, note: "停車位置", photo: nil, dateString: dateString)
                // Save the information in the database(userdefault)
                self.saveParkInformation(coordinate: nowCarLocation, note: "停車位置", photo: nil, dateString: dateString)
                return
            }
            if note != "" {
                // Add the new Pin on the map with note
                self.addNewAnnotationOnMap(coordinate: nowCarLocation, note: note, photo: nil, dateString: dateString)
                // Save the information in the database(userdefault)
                self.saveParkInformation(coordinate: nowCarLocation, note: note, photo: nil, dateString: dateString)
                NSLog("note: \(note)")
            }else{
                // Add the new Pin on the map without note
                self.addNewAnnotationOnMap(coordinate: nowCarLocation, note: "停車位置", photo: nil, dateString: dateString)
                // Save the information in the database(userdefault)
                self.saveParkInformation(coordinate: nowCarLocation, note: "停車位置", photo: nil, dateString: dateString)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        pinAlert.addAction(onlyNote)
        pinAlert.addAction(cancel)
        self.present(pinAlert, animated: true, completion: nil)
    }
    /// Add the new pin on the map
    ///
    /// - Parameters:
    ///   - coordinate: 輸入包含經緯度的座標，用CLLocationCoordinate2D 的物件可包含
    ///   - note: 輸入的註解
    ///   - photo: 拍照相片，可為nil
    ///   - dateString: 儲存的時間string
    func addNewAnnotationOnMap(coordinate:CLLocationCoordinate2D, note:String, photo: UIImage? ,dateString:String){
        let addNewPinQueue = DispatchQueue(label: "addNewPin")
        addNewPinQueue.async {
            let pinAnnotation = MKPointAnnotation()
            pinAnnotation.coordinate = coordinate
            pinAnnotation.title = note
            pinAnnotation.subtitle = dateString
            DispatchQueue.main.async {
                self.mainMapView.addAnnotation(pinAnnotation)
            }
        }
    }
    
    /// 儲存使用者停車位置的資訊
    ///
    /// - Parameters:
    ///   - coordinate: 經緯度的座標，用CLLocationCoordinate2D 的物件可包含
    ///   - note: 輸入的註解
    ///   - photo: 拍照相片，可為nil
    ///   - dateString: 儲存的時間string
    func saveParkInformation(coordinate: CLLocationCoordinate2D ,note: String ,photo: UIImage? ,dateString:String){
        clearParkInformation()
        // save the park's information
        let saveDictionary : Dictionary<String,Any> = ["note" : note ,
                              "latitude" : coordinate.latitude,
                              "longitude" : coordinate.longitude,
                              "date" : dateString,
                              ]
        for element in saveDictionary {
            print("element:\(element)")
        }
        
        goalLocation = coordinate
        // 存到UserDefaults中
        userDefault.set(saveDictionary, forKey: "userParkInfo")
        userDefault.synchronize()
        changeBarButton()
    }
    // Clear userDefaults's object
    func clearParkInformation(){
        // Clear userDefault中"userParkInfo" 中所存的資料
        userDefault.removeObject(forKey: "userParkInfo")
        userDefault.synchronize()
        // 移除所有map 上的 Annotations
        self.mainMapView.removeAnnotations(mainMapView.annotations)
        // 移除goalLocation 存的資料
        goalLocation = nil
        changeBarButton()
    }
    /// 導航至車子所在位置
    func navigationToUserCar(){
        startLocation = self.mainMapView.userLocation.coordinate
        guard startLocation != nil else {
            NSLog("startLocation 是 nil")
            return
        }
        guard let goalCoordinate = goalLocation else {
            NSLog("goalLocation 是 nil")
            return
        }
        if startLocation?.latitude == goalCoordinate.latitude &&
            startLocation?.longitude == goalCoordinate.longitude
        {
            let alert = UIAlertController(title: nil, message: "已抵達目的地", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true) {
                self.begainNavigation = false
                self.mainMapView.removeOverlays(self.mainMapView.overlays)

            }
            return
        }
        // 位置 placeMark
        let placemark = MKPlacemark(coordinate: goalCoordinate)
        /*
         // 使用 Apple Map 導航
         let regionDistance:CLLocationDistance = 1000;
         let regionSpan = MKCoordinateRegion(center: goalCoordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
         
         let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
         let mapItem = MKMapItem(placemark: placemark)
         mapItem.name = "My Car"
         mapItem.openInMaps(launchOptions: options)
         */
        let directionRequest = MKDirections.Request()
        // 設定起始路徑與目的地
        directionRequest.source = MKMapItem.forCurrentLocation()
        directionRequest.destination = MKMapItem(placemark: placemark)
        // 設定導航的方式 交通 走路 自動
        directionRequest.transportType = MKDirectionsTransportType.automobile
        // 計算方位
        let directions = MKDirections(request: directionRequest)
        directions.calculate{
            [weak self](routeResponse, error) in
            guard let routeResponse = routeResponse else {
                return
            }
            DispatchQueue.main.async {
                // 將導航路線放到 map 上
                if let firstRoute = routeResponse.routes.first {
                    if let overlays = self?.mainMapView.overlays{
                        self?.mainMapView.removeOverlays(overlays)
                    }
                    self?.mainMapView.addOverlay(firstRoute.polyline, level: MKOverlayLevel.aboveRoads)
                }
            }
        }
    }
    // Get user saved information
    func getUserSavedInformation()->Bool{
        guard let saveInfo = userDefault.object(forKey: "userParkInfo") as? Dictionary<String,Any> else {
            return false
        }
        var latitude : Double = 0
        var longitude : Double = 0
        var note : String = ""
        var dateString : String = ""
        for element in saveInfo {
            switch element.key{
            case "latitude":
                if let getLatitude = saveInfo["latitude"] as? Double {
                    latitude = getLatitude
                }else{
                    latitude = 0
                }
                break
            case "longitude":
                if let getLongitude = saveInfo["longitude"] as? Double {
                    longitude = getLongitude
                }else{
                    longitude = 0
                }
                break
            case "note":
                if let getNote = saveInfo["note"] as? String {
                    note = getNote
                }else{
                    note = ""
                }
                break
            case "date":
                if let getDate = saveInfo["date"] as? String {
                    dateString = getDate
                }else{
                    dateString = ""
                }
                break
            default:
                break
            }
        }
        let savedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        goalLocation = savedCoordinate
        addNewAnnotationOnMap(coordinate: savedCoordinate, note: note, photo: nil, dateString: dateString)
        return true
    }
    
//Fix
/*
//MARK:- open camera must with imagepickerController delegate function
    // Open and use camera
    func openCamera(){
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
 */
//MARK: - Delegate Function
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension ViewController : MKMapViewDelegate{
    // set pin's style
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation){
            return nil
        }
        let identifier = "Park"
        // MKPinAnnotationView only can change pin color, can't change image
        /*
         var resultPin = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
         if resultPin == nil{
         resultPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
         }else{
         resultPin?.annotation = annotation
         }
         
         resultPin?.pinTintColor = UIColor.blue
         resultPin?.canShowCallout = true
         resultPin?.animatesDrop = true
         
         return resultPin
         */
        // use MKAnnotationView can change to image
        var resultImg = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if resultImg == nil{
            print("resultImg is nil")
            resultImg = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else{
            resultImg?.annotation = annotation
        }
        // 設定 resultImag 會不會顯示輸入的字
        resultImg?.canShowCallout = true
        let image = UIImage(named: "pointRed.png")
        resultImg?.image = image
        let imageView = UIImageView(image: image)
        resultImg?.leftCalloutAccessoryView = imageView
        return resultImg
    }
    // 設定導航路徑的線條
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 3
        return renderer
    }
}
extension ViewController : CLLocationManagerDelegate{
    // Always update address
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let nowLocation = locations.last else {
            print("nowLocation is nil")
            return
        }
        print("目前的座標位置:\(nowLocation.coordinate.latitude),\(nowLocation.coordinate.longitude)")
        if origoLocation == nil {
            // get the start location
            print("first origo")
            guard let startLocation = locationManager?.location?.coordinate else {
                print(Error.self)
                return
            }
            origoLocation = startLocation
            
            // 將所在位址放大
            var region  = MKCoordinateRegion()
            region.center = startLocation
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            // 移到現在的所在位置
            mainMapView.setRegion(region, animated: true)
        }
    }
}
extension ViewController : UIImagePickerControllerDelegate{
    
}
extension ViewController : UINavigationControllerDelegate{
    
}
