//
//  Board.swift
//  Crush
//
//  Created by Chia on 2022/04/09.
//

import Foundation
import UIKit

struct BoardItem {
    var itemNo: Int = 0 {
        didSet {
            updateImage()
        }
    }
    var imageView: UIImageView = UIImageView()
    
    func updateImage() {
        imageView.image = UIImage(named: "item\(itemNo)")
    }
}
