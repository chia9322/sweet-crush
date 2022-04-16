//
//  ShuffleViewController.swift
//  Crush
//
//  Created by Chia on 2022/04/16.
//

import UIKit

class ShuffleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func shuffleButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "unwindAndShuffle", sender: nil)
    }
}
