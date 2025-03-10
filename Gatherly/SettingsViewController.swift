//
//  SettingsViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

var darkMode = true // CHANGE TO WHAT USER HAD STORED

class SettingsViewController: UIViewController {
    
    let segueIdentifier = "LoginFromSettings"

    @IBOutlet weak var darkModeState: UISwitch!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var passwordEdit: UIButton!
    @IBOutlet weak var emailEdit: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        darkModeState.isOn = darkMode
        updateDarkMode(darkMode: darkMode, to: view)
        logoutButton.tintColor = .white
        emailEdit.tintColor = .white
        passwordEdit.tintColor = .white
    }
    
    
    @IBAction func darkModePressed(_ sender: UISwitch) {
        darkMode = darkModeState.isOn
        saveDarkModeToFirestore(darkMode: darkMode)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: self.segueIdentifier, sender:nil)
        } catch {
            showAlert(on: self, title:"Error" , message: "Failed to log out")
        }
    }
    
    func saveDarkModeToFirestore(darkMode: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["darkMode": darkMode]) { error in
            if let error = error {
                showAlert(on: self, title:"Failed to update dark mode" , message: "\(error.localizedDescription)")
            }
        }
    }

}
