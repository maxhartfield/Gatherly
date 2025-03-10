//
//  ChangeNameViewController.swift
//  Gatherly
//
//  Created by Raymond Wang on 3/10/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChangeNameViewController: UIViewController {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    
    var currfname = ""
    var currlname = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchNames()
        updateDarkMode(darkMode: darkMode, to: view)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        
        guard let newfname = firstName.text,
              let newlname = lastName.text else {
                    showAlert(on: self, title: "Error", message: "Please enter a new first and last name.")
                    return
        }
        
        if newfname == self.currfname && newlname == self.currlname {
            showAlert(on: self, title: "Error", message: "Please enter a new first and last name.")
        } else {
            updateNames(newfname: newfname, newlname: newlname)
        }
        
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func fetchNames() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { document, error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let fname = data["firstName"] as? String,
                  let lname = data["lastName"] as? String else {
                showAlert(on: self, title: "Error", message: "Invalid user data format.")
                return
            }
            
            self.currfname = document!["firstName"] as! String
            self.currlname = document!["lastName"] as! String
            print(self.currfname, self.currlname)
        }
    }
    
    func updateNames(newfname : String, newlname : String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }
        
        
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).updateData([
            "firstName": newfname,
            "lastName": newlname
        ]) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to change name: \(error.localizedDescription)")
            } else {
                let alert = UIAlertController(title: "Success", message: "Changed name successfully!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismiss(animated: true) // Dismiss only after user taps "OK"
                })
                self.present(alert, animated: true)
            }
        }
    }
}
