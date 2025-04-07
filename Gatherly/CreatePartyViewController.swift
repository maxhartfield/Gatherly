import UIKit
import FirebaseFirestore
import FirebaseAuth
import EventKit

class CreatePartyViewController: UIViewController {
    @IBOutlet weak var partyNameTextField: UITextField!
    @IBOutlet weak var partyDescriptionTextField: UITextField!
    @IBOutlet weak var dateTimePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        dateTimePicker.minimumDate = Date()
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
              let description = partyDescriptionTextField.text, !description.isEmpty else {
            showAlert(on: self, title: "Missing Fields", message: "Please fill in all fields.")
            return
        }

        let selectedDate = dateTimePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: selectedDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        let timeString = timeFormatter.string(from: selectedDate)

        let partyId = UUID().uuidString

        let partyData: [String: Any] = [
            "partyId": partyId,
            "name": name,
            "description": description,
            "date": dateString,
            "time": timeString,
            "partyType": "General",
            "hostUid": uid,
            "invitees": [uid]
        ]

        let db = Firestore.firestore()
        db.collection("parties").document(partyId).setData(partyData) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to create party: \(error.localizedDescription)")
                return
            }

            db.collection("users").document(uid).updateData([
                "rsvps.\(partyId)": "Going"
            ]) { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to update user data: \(error.localizedDescription)")
                } else {
                    self.addPartyToCalendar(name: name, description: description, startDate: selectedDate)
                    let alert = UIAlertController(
                        title: "Party Created!",
                        message: "Your Party ID: \(partyId)\n\nShare this ID with others so they can join.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                        UIPasteboard.general.string = partyId
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    func addPartyToCalendar(name: String, description: String, startDate: Date) {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        if (status == .fullAccess || status == .writeOnly) && calendarEnabled {
            let event = EKEvent(eventStore: eventStore)
            event.title = name
            event.notes = description
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(15)
            event.calendar = eventStore.defaultCalendarForNewEvents
            let alarm = EKAlarm(relativeOffset: -3600)
            event.addAlarm(alarm)
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("Failed to save calendar event: \(error)")
            }
        }
    }
}
