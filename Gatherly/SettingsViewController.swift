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
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var passwordEdit: UIButton!
    @IBOutlet weak var usernameEdit: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        darkModeState.isOn = darkMode
        updateDarkMode()
        logoutButton.tintColor = .white
        submitButton.tintColor = .white
        usernameEdit.tintColor = .white
        passwordEdit.tintColor = .white
    }
    
    
    @IBAction func darkModePressed(_ sender: UISwitch) {
        darkMode = darkModeState.isOn
        updateDarkMode()
    }
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: self.segueIdentifier, sender:nil)
            // CHANGE to no segue - just pop all previous screens and go back to login with no info or create a new login, otherwise a back button pops up due to the embedding in nav controller
        } catch {
            print("Sign out error")
        }
    }
    
    @objc func updateDarkMode() {
        if let oldGradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
                oldGradientLayer.removeFromSuperlayer()
            }
        if (darkMode){
            let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [
                    UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0).cgColor,  // Blue
                    UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0).cgColor   // Purple
                ]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.frame = view.bounds
                view.layer.insertSublayer(gradientLayer, at: 0)
        } else {
            let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [
                    UIColor(red: 255/255, green: 87/255, blue: 171/255, alpha: 1.0).cgColor,  // Pink
                    UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0).cgColor   // Orange
                ]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.frame = view.bounds
                view.layer.insertSublayer(gradientLayer, at: 0)
            
        } // Applies the correct mode
        }

}
