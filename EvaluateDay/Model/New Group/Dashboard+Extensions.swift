//
//  Dashboard+Extensions.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 02/09/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import RealmSwift
import CoreSpotlight
import CoreServices
import Intents

extension Dashboard {
    var shortcut: NSUserActivity? {
        let activity = NSUserActivity(activityType: SiriShortcutItem.collection.rawValue)
        activity.isEligibleForSearch = true
        
        if #available(iOS 12.0, *) {
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(self.id)
            activity.isEligibleForPrediction = true
        }
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        activity.title = Localizations.Siri.Shortcut.General.Collection.title(self.title)
        attributes.contentDescription = Localizations.Siri.Shortcut.General.Collection.description
        
        if #available(iOS 12.0, *) {
            activity.suggestedInvocationPhrase = Localizations.Siri.Shortcut.General.Collection.suggest
        }
        activity.contentAttributeSet = attributes
        activity.userInfo = ["collection": self.id]
        
        return activity
    }
}

extension Dashboard: CloudKitSyncable {
    func record(zoneID: CKRecordZone.ID) -> CKRecord? {
        let recordId = CKRecord.ID(recordName: self.id, zoneID: zoneID)
        let record = CKRecord(recordType: "Dashboard", recordID: recordId)
        record.setObject(self.title as CKRecordValue, forKey: "title")
        record.setObject(self.image as CKRecordValue, forKey: "image")
        record.setObject(self.created as CKRecordValue, forKey: "created")
        record.setObject(self.edited as CKRecordValue, forKey: "edited")
        record.setObject(self.order as CKRecordValue, forKey: "order")
        
        return record
    }
    
    static func object(record: CKRecord) -> Dashboard? {
        let dashboard = Dashboard()
        dashboard.id = record.recordID.recordName
        dashboard.title = record.object(forKey: "title") as! String
        dashboard.image = record.object(forKey: "image") as! String
        dashboard.created = record.object(forKey: "created") as! Date
        dashboard.edited = record.object(forKey: "edited") as! Date
        dashboard.order = record.object(forKey: "order") as! Int
        return dashboard
    }
    
    typealias CloudKitSyncable = Dashboard
}
