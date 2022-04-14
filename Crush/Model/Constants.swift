//
//  Constants.swift
//  Crush
//
//  Created by Chia on 2022/04/11.
//

import Foundation
import UIKit

let numberOfItemsInColumn = 8
let numberOfItemsInRow = 6

let itemNoRange = 1...6

let changeItemAnimateDuration = 0.3
let dropItemAnimateDuration = 0.4
let clearItemAnimateDuration = 0.1

let minimumDistanceToSwitchItem: CGFloat = 0

let bonusFactorInterval: Double = 0.5

let playTime: Double = 30


enum Move {
    case left, right, up, down, none
}


struct Movement {
    var move: Move
    let row: Int
    let column: Int
}
