//
//  SettingsViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseAuth

var darkMode = true // CHANGE TO WHAT USER HAD STORED

class SettingsViewController: UIViewController {
    
    let segueIdentifier = "LoginFromSettings"

    @IBOutlet weak var darkModeState: UISwitch!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var passwordEdit: UIButton!
    @IBOutlet weak var usernameEdit: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        darkModeState.isOn = darkMode
        updateDarkMode(darkMode: darkMode, to: view)
        logoutButton.tintColor = .white
        usernameEdit.tintColor = .white
        passwordEdit.tintColor = .white
    }
    
    
    @IBAction func darkModePressed(_ sender: UISwitch) {
        darkMode = darkModeState.isOn
        updateDarkMode(darkMode: darkMode, to: view)
    }
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: self.segueIdentifier, sender:nil)
        } catch {
            print("Sign out error")
        }
    }

}
