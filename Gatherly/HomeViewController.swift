//
//  HomeViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import EventKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    var partyIdEntered: String?
    let cellIdentifier = "PartyCardCell"
    @IBOutlet weak var tableView: UITableView!
    var parties: [Party] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        //tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.separatorStyle = .none
        // Do any additional setup after loading the view.
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
        fetchUserParties()
    }
    
    func fetchUserParties() {
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
                  let rsvps = data["rsvps"] as? [String: String] else {
                showAlert(on: self, title: "Error", message: "Invalid user data format.")
                return
            }

            self.parties.removeAll()
            let group = DispatchGroup()
            
            for partyId in rsvps.keys {
                group.enter()
                Firestore.firestore().collection("parties").document(partyId).getDocument { partyDoc, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching party \(partyId): \(error.localizedDescription)")
                        return
                    }
                    
                    if let partyData = partyDoc?.data(),
                       let name = partyData["name"] as? String,
                       let description = partyData["description"] as? String,
                       let dateString = partyData["date"] as? String,
                       let time = partyData["time"] as? String,
                       let partyType = partyData["partyType"] as? String,
                       let hostUid = partyData["hostUid"] as? String {
                        
                        let invitees = partyData["invitees"] as? [String]
                        let assignments = partyData["assignments"] as? [String: String]
                        var party = Party(
                            partyId: partyId,
                            name: name,
                            description: description,
                            date: dateString,
                            time: time,
                            partyType: partyType,
                            invitees: invitees ?? [],
                            hostUid: hostUid,
                            assignments: assignments
                        )
                        party.userRSVPStatus = rsvps[partyId]
                        self.parties.append(party)
                    }
                }
            }

            group.notify(queue: .main) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd h:mm a"
                formatter.locale = Locale(identifier: "en_US_POSIX")

                self.parties.sort {
                    let dateTime1 = "\( $0.date ) \( $0.time )"
                    let dateTime2 = "\( $1.date ) \( $1.time )"
                    
                    guard let d1 = formatter.date(from: dateTime1),
                          let d2 = formatter.date(from: dateTime2) else {
                        return false
                    }

                    if d1 == d2 {
                        return $0.name < $1.name
                    }
                    return d1 < d2
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parties.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PartyCardCell else {
            return UITableViewCell()
        }

        let party = parties[indexPath.row]
        cell.nameLabel.text = party.name
        cell.dateLabel.text = "Date: \(party.date)"
        
        guard let user = Auth.auth().currentUser else { return cell }
        let uid = user.uid

        // Set role
        cell.detailLabel.text = party.hostUid == uid ? "Host" : "Invitee"
        
        switch party.userRSVPStatus {
        case "Going":
            cell.containerView.backgroundColor = .systemGreen.withAlphaComponent(0.8)
        case "Undecided":
            cell.containerView.backgroundColor = .systemYellow.withAlphaComponent(0.9)
        case "Not Going":
            cell.containerView.backgroundColor = .systemRed.withAlphaComponent(0.8)
        default:
            cell.containerView.backgroundColor = .systemGray6
        }

        return cell
    }

        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PartyInfoSegue" {
            if let destinationVC = segue.destination as? PartyInfoViewController,
               let indexPath = tableView.indexPathForSelectedRow {
                let selectedParty = parties[indexPath.row]
                destinationVC.party = selectedParty
                print(selectedParty)
            }
        }
    }

    
    @IBAction func joinButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
           title: "Join Party",
           message: "Enter Party ID",
           preferredStyle: .alert
       )
       
       controller.addTextField { (textField) in
           textField.placeholder = "ex:123456"
       }
       
       controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
       
       controller.addAction(UIAlertAction(title: "OK", style: .default) { _ in
           guard let enteredPartyId = controller.textFields?.first?.text, !enteredPartyId.isEmpty else {
               showAlert(on: self, title: "Invalid Entry", message: "Please enter a valid Party ID.")
               return
           }
           
           self.attemptToJoinParty(partyId: enteredPartyId)
       })
       
       present(controller, animated: true)
    }
    
    func attemptToJoinParty(partyId: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }
        let db = Firestore.firestore()
        let partyRef = db.collection("parties").document(partyId)
        let userRef = db.collection("users").document(uid)
        partyRef.getDocument { (partyDoc, error) in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to check party: \(error.localizedDescription)")
                return
            }
            
            guard let partyData = partyDoc?.data() else {
                showAlert(on: self, title: "Party Not Found", message: "No party exists with this ID.")
                return
            }
            partyRef.updateData([
                "invitees": FieldValue.arrayUnion([uid])
            ]) { error in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to update invitees list: \(error.localizedDescription)")
                }
            }

            
            userRef.getDocument { (userDoc, error) in
                if let error = error {
                    showAlert(on: self, title: "Error", message: "Failed to check user data: \(error.localizedDescription)")
                    return
                }
                guard let userData = userDoc?.data(),
                      let rsvps = userData["rsvps"] as? [String: String] else {
                    showAlert(on: self, title: "Error", message: "Invalid user data format.")
                    return
                }
                if rsvps[partyId] != nil {
                    showAlert(on: self, title: "Already Joined", message: "You have already joined this party.")
                    return
                }
                userRef.updateData([
                    "rsvps.\(partyId)": "Undecided"
                ]) { error in
                    if let error = error {
                        showAlert(on: self, title: "Error", message: "Failed to join party: \(error.localizedDescription)")
                    } else {
                        showAlert(on: self, title: "Success", message: "You have successfully joined the party!")
                        self.fetchUserParties()
                        if let partyDateString = partyData["date"] as? String,
                            let partyTimeString = partyData["time"] as? String,
                            let partyDate = self.parseDate(dateString: partyDateString, timeString: partyTimeString) {
                                self.addPartyToCalendar(name: partyData["name"] as! String,
                                description: partyData["description"] as! String, startDate: partyDate, partyId: partyId)
                                }
                    }
                }
            }
        }
    }
    
    func parseDate(dateString: String, timeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dateTimeString = "\(dateString) \(timeString)"
        return dateFormatter.date(from: dateTimeString)
    }
    
    func addPartyToCalendar(name: String, description: String, startDate: Date, partyId: String) {
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

                if let eventId = event.eventIdentifier {
                    let db = Firestore.firestore()
                    db.collection("parties").document(partyId).updateData([
                        "calendarEventId": eventId
                    ]) { error in
                        if let error = error {
                            print("Failed to save event ID to Firestore: \(error.localizedDescription)")
                        } else {
                            print("Event ID saved to Firestore.")
                        }
                    }
                } else {
                    print("Event ID is nil, not saving to Firestore.")
                }

            } catch {
                print("Failed to save calendar event: \(error)")
            }
        }
    }

}
