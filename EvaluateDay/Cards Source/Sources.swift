//
//  CardsSource.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 25/10/2017.
//  Copyright © 2017 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import HealthKit

final class Sources: NSObject {

    // MARK: - Variables
    var cards = [Source]()
    
    // MARK: - Init
    override init() {
        super.init()
        self.setSources()
    }
    
    // MARK: - Static functions
    static func image(forType type: CardType) -> UIImage {
        switch type {
        case .evaluate:
            return #imageLiteral(resourceName: "appIcon_white")
        case .color:
            return Images.Cards.color.image
        case .checkIn:
            return Images.Cards.checkin.image
        case .phrase:
            return Images.Cards.phrase.image
        case .criterionHundred:
            return Images.Cards.criterionHundred.image
        case .criterionTen:
            return Images.Cards.criterionTen.image
        case .criterionThree:
            return Images.Cards.criterionThree.image
        case .counter:
            return Images.Cards.counter.image
        case .habit:
            return Images.Cards.habit.image
        case .list:
            return Images.Cards.listSource.image
        case .goal:
            return Images.Cards.goal.image
        case .journal:
            return Images.Cards.journal.image
        case .tracker:
            return Images.Cards.tracker.image
        default:
            return #imageLiteral(resourceName: "update")
        }
    }
    
    static func title(forType type: CardType) -> String {
        switch type {
        case .color:
            return Localizations.New.Color.title
        case .checkIn:
            return Localizations.New.Checkin.title
        case .phrase:
            return Localizations.New.Phrase.title
        case .criterionHundred:
            return Localizations.New.CriterionHundred.title
        case .criterionTen:
            return Localizations.New.CriterionTen.title
        case .criterionThree:
            return Localizations.New.CriterionThree.title
        case .counter:
            return Localizations.New.Counter.title
        case .habit:
            return Localizations.New.Habit.title
        case .list:
            return Localizations.New.List.title
        case .goal:
            return Localizations.New.Goal.title
        case .journal:
            return Localizations.New.Journal.title
        case .tracker:
            return Localizations.New.Tracker.title
        default:
            return "none"
        }
    }
    
    // MARK: - Private variables
    private func setSources() {
        self.cards.removeAll()
        
        self.cards.append(Source(type: .color, title: Localizations.New.Color.title, subtitle: Localizations.New.Color.subtitle, image: Sources.image(forType: .color)))
        self.cards.append(Source(type: .checkIn, title: Localizations.New.Checkin.title, subtitle: Localizations.New.Checkin.subtitle, image: Sources.image(forType: .checkIn)))
        self.cards.append(Source(type: .phrase, title: Localizations.New.Phrase.title, subtitle: Localizations.New.Phrase.subtitle, image: Sources.image(forType: .phrase)))
        self.cards.append(Source(type: .criterionHundred, title: Localizations.New.CriterionHundred.title, subtitle: Localizations.New.CriterionHundred.subtitle, image: Sources.image(forType: .criterionHundred)))
        self.cards.append(Source(type: .criterionTen, title: Localizations.New.CriterionTen.title, subtitle: Localizations.New.CriterionTen.subtitle, image: Sources.image(forType: .criterionTen)))
        self.cards.append(Source(type: .criterionThree, title: Localizations.New.CriterionThree.title, subtitle: Localizations.New.CriterionThree.subtitle, image: Sources.image(forType: .criterionThree)))
        self.cards.append(Source(type: .counter, title: Localizations.New.Counter.title, subtitle: Localizations.New.Counter.subtitle, image: Sources.image(forType: .counter)))
        self.cards.append(Source(type: .habit, title: Localizations.New.Habit.title, subtitle: Localizations.New.Habit.subtitle, image: Sources.image(forType: .habit)))
        self.cards.append(Source(type: .tracker, title: Localizations.New.Tracker.title, subtitle: Localizations.New.Tracker.subtitle, image: Sources.image(forType: .tracker)))
        self.cards.append(Source(type: .list, title: Localizations.New.List.title, subtitle: Localizations.New.List.subtitle, image: Sources.image(forType: .list)))
        self.cards.append(Source(type: .goal, title: Localizations.New.Goal.title, subtitle: Localizations.New.Goal.subtitle, image: Sources.image(forType: .goal)))
        self.cards.append(Source(type: .journal, title: Localizations.New.Journal.title, subtitle: Localizations.New.Journal.subtitle, image: Sources.image(forType: .journal)))
    }
}
