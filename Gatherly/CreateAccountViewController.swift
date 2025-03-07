//
//  CreateAccountViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var retypePasswordTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var loginButton: UIButton!
    let segueIdentifier = "HomeFromCreateAccount"

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: true, to: view)
        loginButton.tintColor = .white
        cancelButton.tintColor = .white
        firstNameTextField.backgroundColor = .white
        lastNameTextField.backgroundColor = .white
        emailTextField.backgroundColor = .white
        passwordTextField.backgroundColor = .white
        retypePasswordTextField.backgroundColor = .white
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: self.segueIdentifier, sender:nil)
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
            }
        }
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        
        guard let firstName = firstNameTextField.text,
              let lastName = lastNameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              let retypedPassword = retypePasswordTextField.text else {
            showAlert(on: self, title: "Error", message: "Please fill in all fields")
            return
        }

        guard isValidEmail(email) else {
            showAlert(on: self, title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        guard isValidPassword(password) else {
            showAlert(on: self, title: "Weak Password", message: "Password must be at least 6 characters.")
            return
        }

        guard password == retypedPassword else {
            showAlert(on: self, title: "Password Mismatch", message: "Passwords do not match.")
            return
        }

        Auth.auth().createUser(withEmail: emailTextField.text!,
                               password: passwordTextField.text!) {
            (authResult,error) in
            if let error = error as NSError? {
                showAlert(on: self, title: "Signup Failed", message: "\(error.localizedDescription)")
            }
            guard let uid = authResult?.user.uid else {
                showAlert(on: self, title: "Signup Error", message: "Could not get user ID.")
                return
            }
            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "partyIdsHosting": [],
                "partyIdsAttending": [],
                "rsvps": [:],
                "darkMode": true
            ]
            Firestore.firestore().collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    showAlert(on: self, title: "Firestore Error", message: "Failed to save user: \(error.localizedDescription)")
                } else {
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                }
            }
        }
    }

    func isValidEmail(_ email: String) -> Bool {
       let emailRegEx =
           "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
       let emailPred = NSPredicate(format:"SELF MATCHES %@",
           emailRegEx)
       return emailPred.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
       let minPasswordLength = 6
       return password.count >= minPasswordLength
    }

}
