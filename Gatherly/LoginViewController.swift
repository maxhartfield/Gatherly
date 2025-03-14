//
//  ViewController.swift
//  designDocument
//
//  Created by Samika Iyer on 2/23/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var passwordTextField: UITextField!
    let segueIdentifier = "HomeFromLogin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: true, to: view)
        // Do any additional setup after loading the view.
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.loadUserDarkMode(uid: user!.uid) {
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                    self.emailTextField.text = nil
                    self.passwordTextField.text = nil
                }
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailTextField.text,
                      let password = passwordTextField.text else {
                    showAlert(on: self, title: "Error", message: "Please enter email and password.")
                    return
        }
        Auth.auth().signIn(
            withEmail: emailTextField.text!,
            password: passwordTextField.text!) {
                (authResult,error) in
                if let error = error as NSError? {
                    showAlert(on: self, title: "Signup Failed", message: "\(error.localizedDescription)")
                } else if let user = authResult?.user {
                    self.loadUserDarkMode(uid: user.uid) {
                        self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                    }
                }
        }
    }
    
    func loadUserDarkMode(uid: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { (document, error) in
            if let error = error {
                showAlert(on: self, title: "Failed to fetch dark mode setting:", message: "\(error.localizedDescription)")
            } else if let data = document?.data(), let storedDarkMode = data["darkMode"] as? Bool {
                darkMode = storedDarkMode
                updateDarkMode(darkMode: darkMode, to: self.view)
            }
            completion()
        }
    }
}

