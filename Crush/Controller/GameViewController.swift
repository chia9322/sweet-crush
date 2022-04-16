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
    var hintCounter: Double = showHintInterval
    
    var isGameOver = false
    
    let feedbackGenerator = UISelectionFeedbackGenerator()

    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // get actual width of board view
        boardWidth = Double(boardView.frame.width)
        itemSize = Double(boardWidth) / Double(numberOfColumnsInRow)
        createBoard()
        restart()
    }
    
    // MARK: - Game Control
    
    func restart() {
        isGameOver = false
        enableItemInteraction()
        score = 0
        bonusFactor = 1
        updateItems()
        self.checkConnection(movement: Movement(move: .none, row: 0, column: 0))
        // start timer
        if let timer = timer {
            timer.invalidate()
        }
        counter = playTime
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    func gameOver() {
        isGameOver = true
        if boardItems[0][0].imageView.isUserInteractionEnabled {
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
                        hintCounter = showHintInterval
                        if abs(horizontalDisplacement) > abs(verticalDisplacement) {
                            if horizontalDisplacement < 0 && column > 0 {
                                moveLeft(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .left, row: row, column: column))
                            } else if horizontalDisplacement > 0 && column < numberOfColumnsInRow-1 {
                                moveRight(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .right, row: row, column: column))
                            }
                        } else {
                            if verticalDisplacement < 0 && row > 0 {
                                moveUp(row, column)
                                bonusFactor = 1
                                checkConnection(movement: Movement(move: .up, row: row, column: column))
                            } else if verticalDisplacement > 0 && row < numberOfRowsInColumn-1 {
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
            currentItem.imageView.transform = CGAffineTransform.identity.scaledBy(x: 0.5 , y: 0.5)
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
        for row in 0..<numberOfRowsInColumn {
            var newRow: [BoardItem] = []
            for column in 0..<numberOfColumnsInRow {
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
        for row in 0..<numberOfRowsInColumn {
            for column in 0..<numberOfColumnsInRow {
                let itemNo = Int.random(in: itemNoRange)
                boardItems[row][column].itemNo = itemNo
            }
        }
    }
    
    func disableItemInteraction() {
        for row in 0..<numberOfRowsInColumn {
            for column in 0..<numberOfColumnsInRow {
                boardItems[row][column].imageView.isUserInteractionEnabled = false
            }
        }
    }
    
    func enableItemInteraction() {
        for row in 0..<numberOfRowsInColumn {
            for column in 0..<numberOfColumnsInRow {
                boardItems[row][column].imageView.isUserInteractionEnabled = true
            }
        }
    }
    
    // MARK: - Check Connection
    func checkConnection(movement: Movement) {
        var hasConnection = true
        disableItemInteraction()
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
                } else {
                    let hint = self.getHint()
                    if hint == [] {
                        self.bonusFactor = 1
                        self.updateItems()
                        self.checkConnection(movement: Movement(move: .none, row: 0, column: 0))
                        if let timer = self.timer {
                            timer.invalidate()
                        }
                        self.performSegue(withIdentifier: "showShuffle", sender: nil)
                    }
                }
            }
        }
    }
    
    func checkAllConnection() -> Bool {
        var newScore: Int = 0
        var positionsToDelete: [[Int]] = []
        for row in 0..<numberOfRowsInColumn {
            for column in 0..<numberOfColumnsInRow {
                let connectPositions = getConnection(row: row, column: column)
                var numberOfConnect = 0
                for position in connectPositions {
                    if !positionsToDelete.contains(position) {
                        numberOfConnect += 1
                        positionsToDelete += [position]
                    }
                }
                let connectScore = (numberOfConnect-2) * 10
                if connectScore > 0 {
                    newScore += connectScore
                }
            }
        }
        
        if positionsToDelete != [] {
            score += Int(Double(newScore) * bonusFactor)
            dropItems(positions: positionsToDelete)
            return true
        } else {
            return false
        }
    }
    
    func getItem(row: Int, column: Int) -> Int {
        if row >= 0 && row < numberOfRowsInColumn && column >= 0 && column < numberOfColumnsInRow {
            return boardItems[row][column].itemNo
        }
        return 0
    }
    
    func getRowConnection(row: Int, column: Int) -> [[Int]] {
        let currentItem = boardItems[row][column]
        var positionsToDelete: [[Int]] = [[row, column]]
        // check row
        var toContinue = true
        var columnToCheck = column
        while toContinue {
            columnToCheck += 1
            let itemNo = getItem(row: row, column: columnToCheck)
            if itemNo == currentItem.itemNo {
                positionsToDelete += [[row, columnToCheck]]
            } else {
                toContinue = false
            }
        }
        if positionsToDelete.count >= 3 {
            return positionsToDelete
        } else {
            return []
        }
    }
    
    func getColumnConnection(row: Int, column: Int) -> [[Int]] {
        let currentItem = boardItems[row][column]
        var positionsToDelete: [[Int]] = [[row, column]]
        // check column
        var toContinue = true
        var rowToCheck = row
        while toContinue {
            rowToCheck += 1
            let itemNo = getItem(row: rowToCheck, column: column)
            if itemNo == currentItem.itemNo {
                positionsToDelete += [[rowToCheck, column]]
            } else {
                toContinue = false
            }
        }
        if positionsToDelete.count >= 3 {
            return positionsToDelete
        } else {
            return []
        }
    }
    
    func getConnection(row: Int, column: Int) -> [[Int]] {
        var positionsToDelete: [[Int]] = []
        let rowConnection = getRowConnection(row: row, column: column)
        if rowConnection != [] {
            positionsToDelete += rowConnection
            var columnsToCheck: [Int] = []
            for position in rowConnection {
                columnsToCheck += [position[1]]
            }
            for columnToCheck in columnsToCheck {
                let columnConnection = getColumnConnection(row: row, column: columnToCheck)
                for position in columnConnection {
                    if !positionsToDelete.contains(position) {
                        positionsToDelete += [position]
                    }
                }
            }
        } else {
            let columnConnection = getColumnConnection(row: row, column: column)
            if columnConnection != [] {
                positionsToDelete += columnConnection
            }
        }
        return positionsToDelete
    }
    
    // MARK: - Hint
    func getHint() -> [[Int]]{
        for row in 0..<numberOfRowsInColumn {
            for column in 0..<numberOfColumnsInRow {
                let currentItemNo = boardItems[row][column].itemNo
                // check row
                let columnToCheck = column + 1
                if columnToCheck < numberOfColumnsInRow {
                    let itemNo = boardItems[row][columnToCheck].itemNo
                    if itemNo == currentItemNo {
                        if getItem(row: row-1, column: column-1) == itemNo {
                            return [[row, column-1], [row-1, column-1]]
                        }
                        if getItem(row: row+1, column: column-1) == itemNo {
                            return [[row, column-1], [row+1, column-1]]
                        }
                        if getItem(row: row-1, column: columnToCheck+1) == itemNo {
                            return [[row, columnToCheck+1], [row-1, columnToCheck+1]]
                        }
                        if getItem(row: row+1, column: columnToCheck+1) == itemNo {
                            return [[row, columnToCheck+1], [row+1, columnToCheck+1]]
                        }
                    }
                }
                // check column
                let rowToCheck = row + 1
                if rowToCheck < numberOfRowsInColumn {
                    let itemNo = boardItems[rowToCheck][column].itemNo
                    if itemNo == currentItemNo {
                        if getItem(row: row-1, column: column-1) == itemNo {
                            return [[row-1, column], [row-1, column-1]]
                        }
                        if getItem(row: row-1, column: column+1) == itemNo {
                            return [[row-1, column], [row-1, column+1]]
                        }
                        if getItem(row: rowToCheck+1, column: column-1) == itemNo {
                            return [[rowToCheck+1, column], [rowToCheck+1, column-1]]
                        }
                        if getItem(row: rowToCheck+1, column: column+1) == itemNo {
                            return [[rowToCheck+1, column], [rowToCheck+1, column+1]]
                        }
                    }
                }
            }
        }
        return []
    }
    
    func showHint(imageView: UIImageView) {
        UIView.animate(withDuration: 0.5) {
            imageView.alpha = 0.5
            imageView.transform =  CGAffineTransform.identity.scaledBy(x: 0.4 , y: 0.4)
        }
        UIView.animate(withDuration: 0.5) {
            imageView.alpha = 1
            imageView.transform =  CGAffineTransform.identity.scaledBy(x: 1 , y: 1)
        }
    }

    
    // MARK: - Timer
    @objc func updateCounter() {
        counter = counter <= 0 ? 0 : counter
        timerLabel.text = String(format: "%.1f", counter) + "s"
        if counter <= 0 {
            timer.invalidate()
            gameOver()
        } else {
            counter -= 0.1
            hintCounter -= 0.1
            if hintCounter <= 0 {
                let hint = getHint()
                for position in hint {
                    let imageView = self.boardItems[position[0]][position[1]].imageView
                    showHint(imageView: imageView)
                    hintCounter = 1
                }
            }
        }
    }
    
    // MARK: - Segue
    @IBSegueAction func showResult(_ coder: NSCoder) -> ResultViewController? {
        return ResultViewController(coder: coder, score: score)
    }
    
    @IBAction func unwindAndRestart(_ segue: UIStoryboardSegue) {
        restart()
    }
    
    @IBSegueAction func showShuffle(_ coder: NSCoder) -> ShuffleViewController? {
        return ShuffleViewController(coder: coder)
    }
    
    @IBAction func unwindAndShuffle(_ segue: UIStoryboardSegue) {
        // start timer
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
}

