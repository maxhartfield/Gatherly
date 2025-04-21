import UIKit
import EventKit
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
        let partyRef = db.collection("parties").document(partyId)

        partyRef.updateData([
                "name": updatedName,
                "description": updatedDescription,
                "date": formattedDate,
                "time": formattedTime
            ]) { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to update party: \(error.localizedDescription)")
                } else {
                    partyRef.getDocument { (partyDoc, error) in
                        if let error = error {
                            print("Error retrieving party data: \(error.localizedDescription)")
                            return
                        }
                        
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
                        
                        guard let partyData = partyDoc?.data(),
                              let eventId = partyData["calendarEventId"] as? String else {
                            print("No calendar event ID found.")
                            return
                        }

                        if calendarEnabled {
                            self.updatePartyInCalendar(eventId: eventId, newName: updatedName, newDescription: updatedDescription, newStartDate: selectedDate)
                        }

                        self.updateInviteesCalendar(partyId: partyId, newName: updatedName, newDescription: updatedDescription, newStartDate: selectedDate)
                    }
                }
            }
    }
    
    func updatePartyInCalendar(eventId: String, newName: String, newDescription: String, newStartDate: Date) {
        let eventStore = EKEventStore()
        if let event = eventStore.event(withIdentifier: eventId) {
            event.title = newName
            event.notes = newDescription
            event.startDate = newStartDate
            event.endDate = newStartDate.addingTimeInterval(15)
            event.alarms?.removeAll()
            event.addAlarm(EKAlarm(relativeOffset: -3600))

            do {
                try eventStore.save(event, span: .thisEvent)
                print("Calendar event updated")
            } catch {
                print("Failed to update calendar event: \(error)")
            }
        } else {
            print("No event found with ID: \(eventId)")
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

            if calendarEnabled,
               let eventId = data["calendarEventId"] as? String {
                let status = EKEventStore.authorizationStatus(for: .event)
                if status == .fullAccess || status == .writeOnly {
                    self.deletePartyFromCalendar(eventId: eventId)
                }
            }

            let batch = db.batch()
            var completedCount = 0
            let totalInvitees = invitees.count

            if totalInvitees == 0 {
                batch.deleteDocument(partyRef)
                batch.commit { error in
                    if let error = error {
                        showAlert(on: self, title: "Error", message: "Failed to delete party: \(error.localizedDescription)")
                    } else {
                        showAlert(on: self, title: "Success", message: "Party deleted!") {
                            self.navigationController?.popToRootViewController(animated: false)
                        }
                    }
                }
                return
            }

            for inviteeUid in invitees {
                let userRef = db.collection("users").document(inviteeUid)
                userRef.getDocument { (userDoc, error) in
                    if let userData = userDoc?.data(),
                       let eventId = userData["calendarEventId"] as? String {
                        self.removeInviteeFromCalendar(eventId: eventId)
                    }
                    batch.updateData(["rsvps.\(partyId)": FieldValue.delete()], forDocument: userRef)
                    completedCount += 1
                    if completedCount == totalInvitees {
                        batch.deleteDocument(partyRef)
                        batch.commit { error in
                            if let error = error {
                                showAlert(on: self, title: "Error", message: "Failed to delete party: \(error.localizedDescription)")
                            } else {
                                showAlert(on: self, title: "Success", message: "Party deleted!") {
                                    self.navigationController?.popToRootViewController(animated: false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    func deletePartyFromCalendar(eventId: String) {
        let eventStore = EKEventStore()
        if let event = eventStore.event(withIdentifier: eventId) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("Calendar event deleted")
            } catch {
                print("Failed to delete calendar event: \(error)")
            }
        } else {
            print("No calendar event found with that ID")
        }
    }
    
    func removeInviteeFromCalendar(eventId: String) {
        let eventStore = EKEventStore()
        if let event = eventStore.event(withIdentifier: eventId) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("Invitee's calendar event deleted")
            } catch {
                print("Failed to delete invitee's calendar event: \(error)")
            }
        } else {
            print("No invitee calendar event found with that ID")
        }
    }
    
    func updateInviteesCalendar(partyId: String, newName: String, newDescription: String, newStartDate: Date) {
        let db = Firestore.firestore()
        let partyRef = db.collection("parties").document(partyId)

        partyRef.getDocument { (partyDoc, error) in
            if let error = error {
                print("Error retrieving party data for invitees: \(error.localizedDescription)")
                return
            }
            
            guard let partyData = partyDoc?.data(),
                  let invitees = partyData["invitees"] as? [String] else {
                print("Invalid party data format.")
                return
            }
            for inviteeUid in invitees {
                let userRef = db.collection("users").document(inviteeUid)
                userRef.getDocument { (userDoc, error) in
                    if let error = error {
                        print("Error retrieving user data: \(error.localizedDescription)")
                        return
                    }

                    guard let userData = userDoc?.data() else {
                        print("Invalid user data format.")
                        return
                    }

                    if let eventId = userData["calendarEventId"] as? String {
                        self.updateInviteeCalendar(eventId: eventId, newName: newName, newDescription: newDescription, newStartDate: newStartDate)
                    }
                }
            }
        }
    }

    func updateInviteeCalendar(eventId: String, newName: String, newDescription: String, newStartDate: Date) {
        let eventStore = EKEventStore()
        if let event = eventStore.event(withIdentifier: eventId) {
            event.title = newName
            event.notes = newDescription
            event.startDate = newStartDate
            event.endDate = newStartDate.addingTimeInterval(15)
            event.alarms?.removeAll()
            event.addAlarm(EKAlarm(relativeOffset: -3600))

            do {
                try eventStore.save(event, span: .thisEvent)
                print("Invitee's calendar event updated")
            } catch {
                print("Failed to update invitee's calendar event: \(error)")
            }
        } else {
            print("No invitee calendar event found with ID: \(eventId)")
        }
    }

}
