//
//  ChangePassViewController.swift
//  Gatherly
//
//  Created by Raymond Wang on 3/10/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChangePassViewController: UIViewController {

    @IBOutlet weak var newPass: UITextField!
    @IBOutlet weak var confirmPass: UITextField!
    @IBOutlet weak var oldPass: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        guard let firstpass = newPass.text, let secondpass = confirmPass.text, let oldpass = oldPass.text else {return}
        
        if firstpass != secondpass {
            showAlert(on: self, title: "Error", message: "Passwords do not match.")
            newPass.text = ""
            confirmPass.text = ""
            oldPass.text = ""
            return
        }
        
        if oldpass == firstpass {
            showAlert(on: self, title: "Error", message: "New password must be different.")
            newPass.text = ""
            confirmPass.text = ""
            oldPass.text = ""
            return
        }
        
        updatePass(newpass: firstpass, oldpass: oldpass)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func updatePass(newpass : String, oldpass: String) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }

        // Step 1: Create credential with email and current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldpass)

        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Incorrect password, please try again.")
                return
            }
            
            user.updatePassword(to: newpass) { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Error updating password.")
                } else {
                    let alert = UIAlertController(title: "Success", message: "Changed password successfully!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
