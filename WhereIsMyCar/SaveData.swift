//
//  SaveData.swift
//  WhereIsMyCar
//
//  Created by Uran on 2017/11/10.
//  Copyright © 2017年 Uran. All rights reserved.
//

import UIKit
import CoreLocation
class SaveData: NSObject {
    let userDefaults = UserDefaults.standard
    func saveParkInformation(coordinate: CLLocationCoordinate2D ,note: String ,photo: UIImage? ,dateString:String){
        
        // save the park's information
        let saveDictionary : [String : Any] =
            ["note" : note ,
             "latitude" : coordinate.latitude,
             "longitude" : coordinate.longitude,
             "date" : dateString,]
        for element in saveDictionary {
            print("element:\(element)")
        }
        // 存到UserDefaults中
        userDefaults.set(saveDictionary, forKey: "userParkInfo")
        userDefaults.synchronize()
    }
    func clearParkInformation(){
        // Clear userDefault中"userParkInfo" 中所存的資料
        userDefaults.removeObject(forKey: "userParkInfo")
        userDefaults.synchronize()
    }
}
