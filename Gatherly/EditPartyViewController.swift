import UIKit
import FirebaseFirestore

class EditPartyViewController: UIViewController {
    
    var party: Party?
    
    @IBOutlet weak var dateTimePicker: UIDatePicker!
    @IBOutlet weak var partyName: UITextField!
    @IBOutlet weak var partyDescription: UITextField!
    var delegate: PartyUpdater!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white

        partyName.text = party?.name
        partyDescription.text = party?.description
        if let dateString = party?.date,
           let timeString = party?.time {

            let combinedFormatter = DateFormatter()
            combinedFormatter.dateFormat = "yyyy-MM-dd h:mm a"
            combinedFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let combinedDate = combinedFormatter.date(from: "\(dateString) \(timeString)") {
                dateTimePicker.date = combinedDate
            }
        }
        dateTimePicker.minimumDate = Date()
    }
    
    @IBAction func onSubmitPressed(_ sender: Any) {
        guard let partyId = party?.partyId,
              let updatedName = partyName.text, !updatedName.isEmpty,
              let updatedDescription = partyDescription.text, !updatedDescription.isEmpty else {
            showAlert(on: self, title: "Error", message: "Please fill in all fields before submitting.")
            return
        }

        let selectedDate = dateTimePicker.date

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let formattedDate = dateFormatter.string(from: selectedDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        let formattedTime = timeFormatter.string(from: selectedDate)

        let db = Firestore.firestore()

        db.collection("parties").document(partyId).updateData([
            "name": updatedName,
            "description": updatedDescription,
            "date": formattedDate,
            "time": formattedTime
        ]) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to update party: \(error.localizedDescription)")
            } else {
                showAlert(on: self, title: "Success", message: "Party details updated!") {
                    self.party?.name = updatedName
                    self.party?.description = updatedDescription
                    self.party?.date = formattedDate
                    self.party?.time = formattedTime
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
