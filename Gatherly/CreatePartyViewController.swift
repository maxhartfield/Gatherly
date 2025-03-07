//
//  CreatePartyViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/7/25.
//

import UIKit

class CreatePartyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
}
