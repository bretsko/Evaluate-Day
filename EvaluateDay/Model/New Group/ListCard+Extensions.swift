//
//  ListCard+Extensions.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 24/01/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import Foundation
import RealmSwift
import IGListKit
import CloudKit
import CoreSpotlight
import CoreServices
import Intents

extension ListCard: Editable {
    var sectionController: ListSectionController {
        return ListEditableSection(card: self.card)
    }
    
    var canSave: Bool {
        if self.card.title == "" {
            return false
        }
        
        return true
    }

}

extension ListCard: Mergeable {
    var mergeableSectionController: ListSectionController {
        return ListMergeSection(card: self.card)
    }
}

extension ListCard: Evaluable {
    var evaluateSectionController: ListSectionController {
        return ListEvaluateSection(card: self.card)
    }
    
    func deleteValues() {
        if self.card.realm == nil {
            return
        }
        
        for value in self.values {
            value.isDeleted = true
        }
    }
    
    func hasEvent(forDate date: Date) -> Bool {
        return !self.values.filter("(doneDate >= %@) AND (doneDate <= %@) AND (done=%@)", date.start, date.end, true).isEmpty
    }
    
    func lastEventDate() -> Date? {
        if let last = self.values.sorted(byKeyPath: "created", ascending: true).last {
            return last.created
        }
        
        return nil
    }
    
    func textExport() -> String {
        var txtText = "Title, Subtitle, Created, 'Created - Since 1970', Edited,'Edited - Since 1970', Text, Done, 'Done Date\n"
        
        let sortedValues = self.values.sorted(byKeyPath: "created")
        
        for c in sortedValues {
            var newLine = ""
            let date = DateFormatter.localizedString(from: c.created, dateStyle: .medium, timeStyle: .medium)
            let edited = DateFormatter.localizedString(from: c.edited, dateStyle: .medium, timeStyle: .medium)
            var doneDate = DateFormatter.localizedString(from: c.doneDate, dateStyle: .medium, timeStyle: .medium)
            if !c.done {
                doneDate = "Unset"
            }
            
            newLine = "\(self.card.title), \(self.card.subtitle), \(date), \(c.created.timeIntervalSince1970), \(edited), \(c.edited.timeIntervalSince1970), \(c.text), \(c.done), \(doneDate) \n"
            
            txtText.append(newLine)
        }
        
        return txtText
    }
    
    func shortcut(for item: SiriShortcutItem) -> NSUserActivity? {
        let activity = NSUserActivity(activityType: item.rawValue)
        activity.isEligibleForSearch = true
        
        if #available(iOS 12.0, *) {
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(self.card.id)
            activity.isEligibleForPrediction = true
        }
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        switch item {
        case .openAnalytics:
            activity.title = Localizations.Siri.Shortcut.General.Analytics.title(self.card.title)
            attributes.contentDescription = Localizations.Siri.Shortcut.General.Analytics.description
            
            if #available(iOS 12.0, *) {
                activity.suggestedInvocationPhrase = Localizations.Siri.Shortcut.General.Analytics.suggest
            }
            activity.contentAttributeSet = attributes
        case .listOpen:
            activity.title = Localizations.Siri.Shortcut.List.Open.title
            attributes.contentDescription = Localizations.Siri.Shortcut.List.Open.description
            
            if #available(iOS 12.0, *) {
                activity.suggestedInvocationPhrase = Localizations.Siri.Shortcut.List.Open.suggest
            }
            activity.contentAttributeSet = attributes
        default:
            return nil
        }
        
        activity.userInfo = ["card": self.card.id]
        return activity
    }
    
    var suggestions: [NSUserActivity]? {
        let items: [SiriShortcutItem] = [.listOpen]
        var activities = [NSUserActivity]()
        for i in items {
            if let cardActivity = self.shortcut(for: i) {
                activities.append(cardActivity)
            }
        }
        
        if activities.isEmpty {
            return nil
        }
        
        return activities
    }
}

extension ListCard: Analytical {
    var analyticalSectionController: ListSectionController {
        return ListAnalyticsSection(card: self.card)
    }
}
