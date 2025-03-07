//
//  CreatePartyViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/7/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class CreatePartyViewController: UIViewController {
    @IBOutlet weak var partyNameTextField: UITextField!
    @IBOutlet weak var partyDescriptionTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    var segueIdentifier = "HomeFromCreateParty"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    @IBAction func createPartyButtonPressed(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "User not logged in.")
            return
        }
        
        guard let name = partyNameTextField.text, !name.isEmpty,
              let description = partyDescriptionTextField.text, !description.isEmpty,
              let dateInput = dateTextField.text, !dateInput.isEmpty,
              let time = timeTextField.text, !time.isEmpty else {
            showAlert(on: self, title: "Missing Fields", message: "Please fill in all fields.")
            return
        }
        
        // Validate date format (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let _ = dateFormatter.date(from: dateInput) else {
            showAlert(on: self, title: "Invalid Date", message: "Please enter the date in yyyy-MM-dd format.")
            return
        }
        
        let partyId = UUID().uuidString
        
        let partyData: [String: Any] = [
            "partyId": partyId,
            "name": name,
            "description": description,
            "date": dateInput,
            "time": time,
            "partyType": "General",
            "hostUid": uid,
            "invitees": []
        ]
        
        let db = Firestore.firestore()
        db.collection("parties").document(partyId).setData(partyData) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to create party: \(error.localizedDescription)")
                return
            }
            db.collection("users").document(uid).updateData([
                "partyIdsHosting": FieldValue.arrayUnion([partyId])
            ]) { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to update user data: \(error.localizedDescription)")
                } else {
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                }
            }
        }
    }
}
