//
//  Movement.swift
//  Crush
//
//  Created by Chia on 2022/04/16.
//

import Foundation

struct Movement {
    var move: Move
    let row: Int
    let column: Int
}

enum Move {
    case left, right, up, down, none
}
