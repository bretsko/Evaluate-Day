//
//  CardSettingsSectionTitleNode.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 08/08/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class CardSettingsSectionTitleNode: ASCellNode {

    // MARK: - UI
    var title = ASTextNode()
    
    // MARK: - Init
    init(title: String) {
        
        super.init()
        
        self.title.attributedText = NSAttributedString(string: title.uppercased(), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.text])
        
        self.automaticallyManagesSubnodes = true
    }
    
    // MARK: - Layout
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let titleInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 10.0)
        let titleInset = ASInsetLayoutSpec(insets: titleInsets, child: self.title)
        return titleInset
    }
}
