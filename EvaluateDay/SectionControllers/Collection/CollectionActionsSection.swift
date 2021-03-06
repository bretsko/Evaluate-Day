//
//  CollectionActionsSection.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 30/12/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class CollectionActionsSection: ListSectionController, ASSectionController {
    // MARK: - Override
    override func numberOfItems() -> Int {
        return 3
    }
    
    func nodeForItem(at index: Int) -> ASCellNode {
        return ASCellNode()
    }
    
    func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        
        if index == 0 {
            return {
                let node = CollectionActionNode(title: Localizations.Settings.title, image: UIImage(named: "settings"), isMarked: false)
                node.cover.accessibilityIdentifier = "settings"
                return node
            }
        } else if index == 1 {
            return {
                let node = CollectionActionNode(title: Localizations.Activity.title, image: UIImage(named: "activity"), isMarked: false)
                node.cover.accessibilityIdentifier = "activity"
                return node
            }
        }
        
        return {
            let node = CollectionActionButtonNode()
            node.button.addTarget(self, action: #selector(self.newCollectionAction(sender:)), forControlEvents: .touchUpInside)
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
        if index == 0 {
            let controller = UIStoryboard(name: Storyboards.settings.rawValue, bundle: nil).instantiateInitialViewController()!
            self.viewController?.navigationController?.pushViewController(controller, animated: true)
        } else if index == 1 {
            let controller = UIStoryboard(name: Storyboards.activity.rawValue, bundle: nil).instantiateInitialViewController()!
            self.viewController?.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Actions
    @objc func newCollectionAction(sender: ASButtonNode) {
        let controller = UIStoryboard(name: Storyboards.editCollection.rawValue, bundle: nil).instantiateInitialViewController()!
        self.viewController?.navigationController?.pushViewController(controller, animated: true)
    }
}
