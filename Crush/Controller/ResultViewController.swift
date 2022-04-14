//
//  ResultViewController.swift
//  Crush
//
//  Created by Chia on 2022/04/14.
//

import UIKit

class ResultViewController: UIViewController {
    
    var score: Int
    var highestScore: Int = 0 {
        didSet {
            highestScoreLabel.text = "Highest Score : \(highestScore)"
        }
    }
    
    init?(coder: NSCoder, score: Int) {
        self.score = score
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highestScoreLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        scoreLabel.text = "\(score)"
        
        let userDefault = UserDefaults.standard
        highestScore = userDefault.integer(forKey: "highestScore")
        if score > highestScore {
            highestScore = score
            userDefault.set(score, forKey: "highestScore")
        }
        
        
    }
}
