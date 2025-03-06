//
//  ViewController.swift
//  designDocument
//
//  Created by Samika Iyer on 2/23/25.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    let segueIdentifier = "HomeFromLogin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
                      let password = passwordTextField.text else {
                    showAlert(title: "Error", message: "Please enter email and password.")
                    return
        }
        Auth.auth().signIn(
            withEmail: emailTextField.text!,
            password: passwordTextField.text!) {
                (authResult,error) in
                if let error = error as NSError? {
                    self.showAlert(title: "Signup Failed", message: "\(error.localizedDescription)")
                }
        }
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }
    
}

