//
//  getDate.swift
//  WhereIsMyCar
//
//  Created by Uran on 2017/11/9.
//  Copyright © 2017年 Uran. All rights reserved.
//

import UIKit

class GetDate: NSObject {
    private var now = Date()
    func getNowTimeString()->String{
        //拿到現在時間
        now = Date()
        // 建立日期格式
        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
//        NSLog("現在時間：\(dateFormate.string(from: now))")
        return dateFormate.string(from: now)
    }
    func dateToTimeStamp(date:Date)->Int{
        //拿到現在的時間戳記
        let timeInterval = date.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        //        NSLog("時間戳記：\(timeStamp)")
        return timeStamp
    }
    func timeStampChangetoTime(timeStamp : Int)->String{
        let timeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)
        
        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        let changeTime = dateFormate.string(from: date)
//        NSLog("對應的時間是：\(dateFormate.string(from: date))")
        return changeTime
    }
}
