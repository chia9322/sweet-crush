//
//  ViewController.swift
//  Crush
//
//  Created by Chia on 2022/04/09.
//

import UIKit

class GameViewController: UIViewController {
    
    var boardWidth: Double = 0
    var itemSize: Double = 0
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    var bonusFactor: Double = 1
    var boardItems: [[BoardItem]] = []
    
    // Timer
    var counter: Double!
    var timer: Timer!
    
    var isGameOver = false
    
    let feedbackGenerator = UISelectionFeedbackGenerator()

    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var randomButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // get actual width of board view
        boardWidth = Double(boardView.frame.width)
        itemSize = Double(boardWidth) / Double(numberOfItemsInRow)
        createBoard()
        restart()
    }
    
    @IBAction func randomButtonPressed(_ sender: UIButton) {
        bonusFactor = 1
        updateItems()
        checkConnection(movement: Movement(move: .none, row: 0, column: 0))
    }
    
    func restart() {
        isGameOver = false
        enableItemInteraction()
        score = 0
        bonusFactor = 1
        updateItems()
        checkConnection(movement: Movement(move: .none, row: 0, column: 0))
        // start timer
        if let timer = timer {
            timer.invalidate()
        }
        counter = playTime
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    func gameOver() {
        isGameOver = true
        if randomButton.isEnabled {
            performSegue(withIdentifier: "showResult", sender: nil)
        }
    }
    
    // MARK: - Switch Item
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let view = touch.view else { return }
        if let view = view as? UIImageView {
            for (row, boardItemsRow) in boardItems.enumerated() {
                for (column, currentItem) in boardItemsRow.enumerated() {
                    if currentItem.imageView == view {
                        let oldLocation = touch.previousLocation(in: self.view)
                        let newLocation = touch.location(in: self.view)
                        let horizontalDisplacement = newLocation.x - oldLocation.x
                        let verticalDisplacement = newLocation.y - oldLocation.y
                        // touch without movement
                        if abs(horizontalDisplacement) <= minimumDistanceToSwitchItem && abs(verticalDisplacement) <= minimumDistanceToSwitchItem {
                            return
                        }
                        // create movement
                        if abs(horizontalDisplacement) > abs(verticalDisplacement) {
                            if horizontalDisplacement < 0 && column > 0 {
                                moveLeft(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .left, row: row, column: column))
                            } else if horizontalDisplacement > 0 && column < numberOfItemsInRow-1 {
                                moveRight(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .right, row: row, column: column))
                            }
                        } else {
                            if verticalDisplacement < 0 && row > 0 {
                                moveUp(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .up, row: row, column: column))
                            } else if verticalDisplacement > 0 && row < numberOfItemsInColumn-1 {
                                moveDown(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .down, row: row, column: column))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Move Item
    func moveLeft(_ row: Int, _ column: Int) {
        let currentItem = boardItems[row][column]
        let leftItem = boardItems[row][column-1]
        UIView.animate(withDuration: changeItemAnimateDuration) {
            currentItem.imageView.frame.origin.x -= self.itemSize
            leftItem.imageView.frame.origin.x += self.itemSize
        }
        boardItems[row][column] = leftItem
        boardItems[row][column-1] = currentItem
    }
    func moveRight(_ row: Int, _ column: Int) {
        let currentItem = boardItems[row][column]
        let rightItem = boardItems[row][column+1]
        UIView.animate(withDuration: changeItemAnimateDuration) {
            currentItem.imageView.frame.origin.x += self.itemSize
            rightItem.imageView.frame.origin.x -= self.itemSize
        }
        boardItems[row][column] = rightItem
        boardItems[row][column+1] = currentItem
    }
    func moveUp(_ row: Int, _ column: Int) {
        let currentItem = boardItems[row][column]
        let topItem = boardItems[row-1][column]
        UIView.animate(withDuration: changeItemAnimateDuration) {
            currentItem.imageView.frame.origin.y -= self.itemSize
            topItem.imageView.frame.origin.y += self.itemSize
        }
        boardItems[row][column] = topItem
        boardItems[row-1][column] = currentItem
    }
    func moveDown(_ row: Int, _ column: Int) {
        let currentItem = boardItems[row][column]
        let bottomItem = boardItems[row+1][column]
        UIView.animate(withDuration: changeItemAnimateDuration) {
            currentItem.imageView.frame.origin.y += self.itemSize
            bottomItem.imageView.frame.origin.y -= self.itemSize
        }
        boardItems[row][column] = bottomItem
        boardItems[row+1][column] = currentItem
    }
    
    // MARK: - Drop Item
    func dropItem(row: Int, column: Int) {
        var currentItem = boardItems[row][column]
        UIView.animate(withDuration: clearItemAnimateDuration) {
            currentItem.imageView.transform = CGAffineTransform.identity.scaledBy(x: 0.1 , y: 0.1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + clearItemAnimateDuration) {
            UIView.animate(withDuration: dropItemAnimateDuration) {
                for rowToDrop in (0..<row).reversed() {
                    let item = self.boardItems[rowToDrop][column]
                    item.imageView.frame.origin.y += self.itemSize
                    self.boardItems[rowToDrop+1][column] = item
                }
                currentItem.imageView.frame.origin.y += self.itemSize
                currentItem.itemNo = Int.random(in: itemNoRange)
            }
            currentItem.imageView.transform = CGAffineTransform.identity.scaledBy(x: 1 , y: 1)
            currentItem.imageView.frame.origin.y -= CGFloat(row+1) * self.itemSize
            self.boardItems[0][column] = currentItem
        }
    }
    
    func dropItems(positions: [[Int]]) {
        var rowsToDrop: [Int] = []
        for position in positions {
            if !rowsToDrop.contains(position[0]) {
                rowsToDrop += [position[0]]
            }
        }
        rowsToDrop = rowsToDrop.sorted()
        for row in rowsToDrop {
            for position in positions {
                if position[0] == row {
                    dropItem(row: row, column: position[1])
                }
            }
        }
    }
    
    // MARK: - Create Board
    func createBoard() {
        for row in 0..<numberOfItemsInColumn {
            var newRow: [BoardItem] = []
            for column in 0..<numberOfItemsInRow {
                let itemImageView = UIImageView(image: UIImage(named: "item1"))
                itemImageView.frame = CGRect(x: Double(column) * itemSize, y: Double(row) * itemSize, width: itemSize, height: itemSize)
                itemImageView.isUserInteractionEnabled = true
                boardView.addSubview(itemImageView)
                newRow += [BoardItem(itemNo: 1, imageView: itemImageView)]
            }
            boardItems += [newRow]
        }
    }
    
    // MARK: - Update Item
    func updateItems() {
        for row in 0..<numberOfItemsInColumn {
            for column in 0..<numberOfItemsInRow {
                let itemNo = Int.random(in: itemNoRange)
                boardItems[row][column].itemNo = itemNo
            }
        }
    }
    
    func unableItemInteraction() {
        randomButton.isEnabled = false
        for row in 0..<numberOfItemsInColumn {
            for column in 0..<numberOfItemsInRow {
                boardItems[row][column].imageView.isUserInteractionEnabled = false
            }
        }
    }
    
    func enableItemInteraction() {
        randomButton.isEnabled = true
        for row in 0..<numberOfItemsInColumn {
            for column in 0..<numberOfItemsInRow {
                boardItems[row][column].imageView.isUserInteractionEnabled = true
            }
        }
    }
    
    // MARK: - Check Connection
    func checkConnection(movement: Movement) {
        var hasConnection = true
        unableItemInteraction()
        DispatchQueue.main.asyncAfter(deadline: .now() + dropItemAnimateDuration + clearItemAnimateDuration) {
            hasConnection = self.checkAllConnection()
            if hasConnection {
                self.feedbackGenerator.selectionChanged()
                self.bonusFactor += bonusFactorInterval
                var newMovement = movement
                newMovement.move = .none
                self.checkConnection(movement: newMovement)
            } else {
                switch movement.move {
                case .none: break
                case .left: self.moveLeft(movement.row, movement.column)
                case .right: self.moveRight(movement.row, movement.column)
                case .up: self.moveUp(movement.row, movement.column)
                case .down: self.moveDown(movement.row, movement.column)
                }
                self.enableItemInteraction()
                if self.isGameOver {
                    self.performSegue(withIdentifier: "showResult", sender: nil)
                }
            }
        }
    }
    
    func checkAllConnection() -> Bool {
        var hasConnection = false
        var positionsToDelete: [[Int]] = []
        for row in (0..<numberOfItemsInColumn).reversed() {
            for column in 0..<numberOfItemsInRow {
                let newPositionsToDelete = checkBothConnection(row: row, column: column)
                if newPositionsToDelete != [[]] {
                    hasConnection = true
                    for newPosition in newPositionsToDelete {
                        if !positionsToDelete.contains(newPosition) {
                            positionsToDelete += [newPosition]
                        }
                    }
                }
            }
        }
        if hasConnection {
            print(positionsToDelete)
            dropItems(positions: positionsToDelete)
        }
        return hasConnection
    }
    
    func checkBothConnection(row: Int, column: Int) -> [[Int]] {
        var positionsToDelete: [[Int]] = []
        let columnsWithSameItem = getRowConnection(row: row, column: column)
        if columnsWithSameItem.count >= 3 {
            for column in columnsWithSameItem {
                positionsToDelete += [[row, column]]
            }
            for columnToCheck in columnsWithSameItem {
                let rowsToDelete = getColumnConnection(row: row, column: columnToCheck)
                if rowsToDelete.count >= 3 {
                    for row in rowsToDelete {
                        if !positionsToDelete.contains([row, columnToCheck]) {
                            positionsToDelete += [[row, columnToCheck]]
                        }
                    }
                }
            }
            score += Int(10 * bonusFactor) * (positionsToDelete.count-2)
            return positionsToDelete
        }
        
        let rowsWithSameItem = getColumnConnection(row: row, column: column)
        if rowsWithSameItem.count >= 3 {
            for row in rowsWithSameItem {
                positionsToDelete += [[row, column]]
            }
            for rowToCheck in rowsWithSameItem {
                let columnsToDelete = getRowConnection(row: rowToCheck, column: column)
                if columnsToDelete.count >= 3 {
                    for column in columnsToDelete {
                        if !positionsToDelete.contains([rowToCheck, column]) {
                            positionsToDelete += [[rowToCheck, column]]
                        }
                    }
                }
            }
            score += Int(10 * bonusFactor) * (positionsToDelete.count-2)
            return positionsToDelete
        }
        return [[]]
    }
    
    func getRowConnection(row: Int, column: Int) -> [Int] {
        let currentItem = boardItems[row][column]
        var columnsWithSameItem = [column]
        // check left
        for i in 1..<numberOfItemsInRow {
            let columnToCheck: Int = (column - i)
            if columnToCheck >= 0 {
                let itemToCheck = boardItems[row][columnToCheck]
                if itemToCheck.itemNo == currentItem.itemNo {
                    columnsWithSameItem += [columnToCheck]
                } else { break }
            } else { break }
        }
        // check right
        for i in 1..<numberOfItemsInRow {
            let columnToCheck: Int = (column + i)
            if columnToCheck < numberOfItemsInRow {
                let itemToCheck = boardItems[row][columnToCheck]
                if itemToCheck.itemNo == currentItem.itemNo {
                    columnsWithSameItem += [columnToCheck]
                } else { break }
            } else { break }
        }
        columnsWithSameItem = columnsWithSameItem.sorted()
        return columnsWithSameItem
    }
    
    func getColumnConnection(row: Int, column: Int) -> [Int] {
        let currentItem = boardItems[row][column]
        var rowsWithSameItem = [row]
        // check top
        for i in 1..<numberOfItemsInColumn {
            let rowToCheck: Int = (row - i)
            if rowToCheck >= 0 {
                let itemToCheck = boardItems[rowToCheck][column]
                if itemToCheck.itemNo == currentItem.itemNo {
                    rowsWithSameItem += [rowToCheck]
                } else { break }
            } else { break }
        }
        // check bottom
        for i in 1..<numberOfItemsInColumn {
            let rowToCheck: Int = (row + i)
            if rowToCheck < numberOfItemsInColumn {
                let itemToCheck = boardItems[rowToCheck][column]
                if itemToCheck.itemNo == currentItem.itemNo {
                    rowsWithSameItem += [rowToCheck]
                } else { break }
            } else { break }
        }
        rowsWithSameItem = rowsWithSameItem.sorted()
        return rowsWithSameItem
        
    }
    
    // MARK: - Hint
//    func getHint() {
//        for row in 0..<numberOfItemsInColumn {
//            for column in 0..<numberOfItemsInRow {
//                let currentItem = boardItems[row][column]
//
//            }
//        }
//    }

    
    // MARK: - Timer
    @objc func updateCounter() {
        counter = counter <= 0 ? 0 : counter
        timerLabel.text = String(format: "%.1f", counter) + "s"
        if counter <= 0 {
            timer.invalidate()
            gameOver()
        } else {
            counter -= 0.1
        }
    }
    
    // MARK: - Segue
    @IBSegueAction func showResult(_ coder: NSCoder) -> ResultViewController? {
        return ResultViewController(coder: coder, score: score)
    }
    
    @IBAction func unwindToGameViewController(_ segue: UIStoryboardSegue) {
        restart()
    }
}

