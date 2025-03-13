//
//  EditPartyViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/12/25.
//

import UIKit
import FirebaseFirestore

class EditPartyViewController: UIViewController {
    
    var party: Party?

    @IBOutlet weak var partyName: UITextField!
    @IBOutlet weak var partyDescription: UITextField!
    @IBOutlet weak var partyDate: UITextField!
    @IBOutlet weak var partyTime: UITextField!
    var delegate: PartyUpdater!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        partyName.text = party?.name
        partyDescription.text = party?.description
        partyDate.text = party?.date
        partyTime.text = party?.time
    }
    
    @IBAction func onSubmitPressed(_ sender: Any) {
        guard let partyId = party?.partyId,
              let updatedName = partyName.text, !updatedName.isEmpty,
              let updatedDescription = partyDescription.text, !updatedDescription.isEmpty,
              let updatedDate = partyDate.text, !updatedDate.isEmpty,
              let updatedTime = partyTime.text, !updatedTime.isEmpty else {
            showAlert(on: self, title: "Error", message: "Please fill in all fields before submitting.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard dateFormatter.date(from: updatedDate) != nil else {
            showAlert(on: self, title: "Invalid Date", message: "Please enter the date in yyyy-MM-dd format.")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("parties").document(partyId).updateData([
            "name": updatedName,
            "description": updatedDescription,
            "date": updatedDate,
            "time": updatedTime
        ]) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to update party: \(error.localizedDescription)")
            } else {
                showAlert(on: self, title: "Success", message: "Party details updated!") {
                    self.party?.name = updatedName
                    self.party?.description = updatedDescription
                    self.party?.date = updatedDate
                    self.party?.time = updatedTime
                    if let updatedParty = self.party {
                        self.delegate?.updateParty(updatedParty)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @IBAction func onDeletePressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Deletion",
                                      message: "Are you sure you want to delete this party? This action cannot be undone.",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteParty()
        }))

        present(alert, animated: true, completion: nil)
    }
    
    func deleteParty() {
        guard let partyId = party?.partyId else { return }
        let db = Firestore.firestore()
        let partyRef = db.collection("parties").document(partyId)
        
        partyRef.getDocument { (document, error) in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to retrieve party data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let invitees = data["invitees"] as? [String] else {
                showAlert(on: self, title: "Error", message: "Invalid party data.")
                return
            }
            
            let batch = db.batch()
            
            for inviteeUid in invitees {
                let userRef = db.collection("users").document(inviteeUid)
                batch.updateData(["rsvps.\(partyId)": FieldValue.delete()], forDocument: userRef)
            }
            
            batch.deleteDocument(partyRef)
            batch.commit { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to delete party: \(error.localizedDescription)")
                } else {
                    showAlert(on: self, title: "Success", message: "Party deleted!") {
                        self.navigationController!.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
}
