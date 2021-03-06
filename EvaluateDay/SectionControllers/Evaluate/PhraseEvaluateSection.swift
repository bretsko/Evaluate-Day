//
//  PhraseEvaluateSection.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 18/01/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import IGListKit
import AsyncDisplayKit
import Branch
import RealmSwift

class PhraseEvaluateSection: ListSectionController, ASSectionController, EvaluableSection, TextViewControllerDelegate {
    // MARK: - Variable
    var card: Card!
    var date: Date!
    
    // MARK: - Actions
    var didSelectItem: ((Int, Card) -> Void)?
    
    // MARK: - Init
    init(card: Card) {
        super.init()
        if let realmCard = Database.manager.data.objects(Card.self).filter("id=%@", card.id).first {
            self.card = realmCard
        } else {
            self.card = card
        }
    }
    
    // MARK: - Override
    override func numberOfItems() -> Int {
        return 1
    }
    
    func nodeForItem(at index: Int) -> ASCellNode {
        return ASCellNode()
    }
    
    func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        var lock = false
        if self.date.start.days(to: Date().start) > pastDaysLimit && !Store.current.isPro {
            lock = true
        }
        
        if self.card.archived {
            lock = true
        }
        
        let title: String
        if self.card.archived {
            title = cardArchivedMark + self.card.title
        } else {
            title = self.card.title
        }
        let subtitle = self.card.subtitle
        
        let phraseCard = self.card.data as! PhraseCard
        var text = Localizations.Evaluate.Phrase.empty
        if let value = phraseCard.values.filter("(created >= %@) AND (created <= %@)", self.date.start, self.date.end).first {
            text = value.text
        }
        
        var values = [Bool]()
        for i in 1...7 {
            var components = DateComponents()
            components.day = i * -1
            let date = Calendar.current.date(byAdding: components, to: self.date)!
            if phraseCard.values.filter("(created >= %@) AND (created <= %@)", date.start, date.end).first != nil {
                values.insert(true, at: 0)
            } else {
                values.insert(false, at: 0)
            }
        }
        
        let board = self.card.dashboardValue
        
        return {
            let node = PhraseNode(title: title, subtitle: subtitle, text: text, date: self.date, values: values, dashboard: board)
            
            node.analytics.button.addTarget(self, action: #selector(self.analyticsButton(sender:)), forControlEvents: .touchUpInside)
            node.share.shareButton.addTarget(self, action: #selector(self.shareAction(sender:)), forControlEvents: .touchUpInside)

            if !lock {
                node.phrase.editButton.addTarget(self, action: #selector(self.editTextAction(sender:)), forControlEvents: .touchUpInside)
            }
            
            return node
        }
    }
    
    func sizeRangeForItem(at index: Int) -> ASSizeRange {
        let width: CGFloat = self.collectionContext!.containerSize.width
        
        if  width >= maxCollectionWidth {
            let max = CGSize(width: width * collectionViewWidthDevider, height: CGFloat.greatestFiniteMagnitude)
            let min = CGSize(width: width * collectionViewWidthDevider, height: 0)
            return ASSizeRange(min: min, max: max)
        }
        
        let max = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let min = CGSize(width: width, height: 0)
        return ASSizeRange(min: min, max: max)
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return .zero
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        return collectionContext!.dequeueReusableCell(of: _ASCollectionViewCell.self, for: self, at: index)
    }
    
    override func didSelectItem(at index: Int) {
    }
    
    // MARK: - TextViewControllerDelegate
    func textTopController(controller: TextViewController, willCloseWith text: String, forProperty property: String) {
        let phraseCard = self.card.data as! PhraseCard
        if phraseCard.realm != nil {
            if let value = phraseCard.values.filter("(created >= %@) AND (created <= %@)", self.date.start, self.date.end).sorted(byKeyPath: "edited", ascending: false).first {
                try! Database.manager.data.write {
                    value.text = text
                    value.edited = Date()
                }
            } else {
                let newValue = TextValue()
                newValue.text = text
                newValue.owner = self.card.id
                newValue.created = self.date
                try! Database.manager.data.write {
                    Database.manager.data.add(newValue)
                }
            }
            
            self.viewController?.userActivity = self.card.data.shortcut(for: .evaluate)
            self.viewController?.userActivity?.becomeCurrent()
            
            collectionContext?.performBatch(animated: true, updates: { (batchContext) in
                batchContext.reload(self)
            }, completion: nil)
        }
    }
    
    // MARK: - Actions
    @objc private func analyticsButton(sender: ASButtonNode) {
        self.didSelectItem?(self.section, self.card)
    }
    
    @objc private func editTextAction(sender: ASButtonNode) {
        let controller = UIStoryboard(name: Storyboards.text.rawValue, bundle: nil).instantiateInitialViewController() as! TextViewController
        controller.delegate = self
        if let value = (self.card.data as! PhraseCard).values.filter("(created >= %@) AND (created <= %@)", self.date.start, self.date.end).first {
            controller.text = value.text
        }
        
        //Feedback
        Feedback.player.play(sound: nil, hapticFeedback: true, impact: false, feedbackType: nil)
        
        self.viewController?.present(controller, animated: true, completion: nil)
    }
    
    @objc private func shareAction(sender: ASButtonNode) {
        let node: PhraseNode!
        
        if let controller = self.viewController as? EvaluateViewController {
            if let tNode = controller.collectionNode.nodeForItem(at: IndexPath(row: 0, section: self.section)) as? PhraseNode {
                node = tNode
            } else {
                return
            }
            
        } else {
            return
        }
        
        node.share.shareCover.alpha = 0.0
        node.share.shareImage.alpha = 0.0
        
        if let nodeImage = node.view.snapshot {
            let sv = ShareView(image: nodeImage)
            UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sv)
            sv.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.leading.equalToSuperview()
            }
            sv.layoutIfNeeded()
            let im = sv.snapshot
            sv.removeFromSuperview()
            
            let shareContrroller = UIStoryboard(name: Storyboards.share.rawValue, bundle: nil).instantiateInitialViewController() as! ShareViewController
            shareContrroller.image = im
            shareContrroller.canonicalIdentifier = "phraseShare"
            shareContrroller.channel = "Evaluate"
            shareContrroller.shareHandler = { () in
                sendEvent(.shareFromEvaluateDay, withProperties: ["type": self.card.type.string])
            }
            
            self.viewController?.present(shareContrroller, animated: true, completion: nil)
        }
        
        node.share.shareCover.alpha = 1.0
        node.share.shareImage.alpha = 1.0
    }
    
    func performAction(for shortcut: SiriShortcutItem) {
        if shortcut == .phraseEdit {
            self.editTextAction(sender: ASButtonNode())
        }
    }
}

class PhraseNode: ASCellNode {
    // MARK: - UI
    var title: TitleNode!
    var phrase: PhraseEvaluateNode!
    var separator: SeparatorNode!
    var analytics: EvaluateDotsAnalyticsNode!
    var share: ShareNode!
    
    private var accessibilityNode = ASDisplayNode()
    
    // MARK: - Init
    init(title: String, subtitle: String, text: String, date: Date, values: [Bool], dashboard: (String, UIImage)?) {
        super.init()
        
        self.backgroundColor = UIColor.background
        
        self.title = TitleNode(title: title, subtitle: subtitle, image: Sources.image(forType: .phrase))
        self.phrase = PhraseEvaluateNode(text: text, date: date)
        self.analytics = EvaluateDotsAnalyticsNode(values: values)
        self.separator = SeparatorNode()
        self.separator.insets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 0.0, right: 20.0)
        
        self.share = ShareNode(dashboardImage: dashboard?.1, collectionTitle: dashboard?.0, cardTitle: title)
        
        // Accessibility
        self.accessibilityNode.isAccessibilityElement = true
        self.accessibilityNode.accessibilityLabel = "\(title), \(subtitle), \(Sources.title(forType: .phrase))"
        self.accessibilityNode.accessibilityTraits = UIAccessibilityTraits.button
        
        self.automaticallyManagesSubnodes = true
    }
    
    // MARK: - Override
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec.vertical()
        stack.children = [self.title, self.phrase, self.analytics, self.share, self.separator]
        
        let cell = ASBackgroundLayoutSpec(child: stack, background: self.accessibilityNode)
        return cell
    }
}
