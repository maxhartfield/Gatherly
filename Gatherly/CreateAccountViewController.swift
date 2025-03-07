//
//  CreateAccountViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseAuth

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
        let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0).cgColor,  // Blue
                UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0).cgColor   // Purple
            ]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.frame = view.bounds
            view.layer.insertSublayer(gradientLayer, at: 0)
        loginButton.tintColor = .white
        cancelButton.tintColor = .white
        firstNameTextField.tintColor = .white
        lastNameTextField.tintColor = .white
        emailTextField.tintColor = .white
        passwordTextField.tintColor = .white
        retypePasswordTextField.tintColor = .white
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
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let retypedPassword = retypePasswordTextField.text else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard isValidEmail(email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        guard isValidPassword(password) else {
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters.")
            return
        }

        guard password == retypedPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords do not match.")
            return
        }

        Auth.auth().createUser(withEmail: emailTextField.text!,
                               password: passwordTextField.text!) {
            (authResult,error) in
            if let error = error as NSError? {
                self.showAlert(title: "Signup Failed", message: "\(error.localizedDescription)")
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

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }


}
