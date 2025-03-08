//
//  HomeViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    var partyIdEntered: String?
    let cellIdentifier = "UserPartyCell"
    @IBOutlet weak var tableView: UITableView!
    var parties: [Party] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        // Do any additional setup after loading the view.
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        fetchUserParties()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
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
                  let partyIdsHosting = data["partyIdsHosting"] as? [String],
                  let partyIdsAttending = data["partyIdsAttending"] as? [String],
                  let rsvps = data["rsvps"] as? [String: String] else {
                showAlert(on: self, title: "Error", message: "Invalid user data format.")
                return
            }
            
            let allPartyIds = partyIdsHosting + partyIdsAttending
            self.parties.removeAll()
            
            let group = DispatchGroup()
            
            for partyId in allPartyIds {
                group.enter()
                
                Firestore.firestore().collection("parties").document(partyId).getDocument { partyDoc, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching party \(partyId): \(error.localizedDescription)")
                        return
                    }
                    
                    if let partyData = partyDoc?.data(),
                       let name = partyData["name"] as? String,
                       let dateString = partyData["date"] as? String,
                       let time = partyData["time"] as? String,
                       let hostUid = partyData["hostUid"] as? String {
                        
                        let isHost = (hostUid == uid)
                        let rsvpStatus = rsvps[partyId] ?? "Undecided"
                        
                        let party = Party(partyId: partyId, name: name, date: dateString, time: time, rsvpStatus: rsvpStatus, isHost: isHost)
                        self.parties.append(party)
                    }
                }
            }
            group.notify(queue: .main) {
                self.parties.sort { $0.date < $1.date }
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parties.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let party = parties[indexPath.row]
        
        cell.textLabel?.text = "\(party.name) - \(party.date) at \(party.time)"
        cell.detailTextLabel?.text = party.isHost ? "Host" : "Invitee"
        cell.detailTextLabel?.textColor = .white
        
        print(party.rsvpStatus)
        switch party.rsvpStatus {
        case "Going":
            cell.contentView.backgroundColor = .systemGreen
        case "Undecided":
            cell.contentView.backgroundColor = .systemYellow
        case "Not Going":
            cell.contentView.backgroundColor = .systemRed
        default:
            cell.contentView.backgroundColor = .systemGray
        }
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedParty = parties[indexPath.row]
        print("Selected party: \(selectedParty.name), RSVP: \(selectedParty.rsvpStatus)")
        //segue
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
            
            let inviteeData = [
                "uid": uid,
                "rsvp": "Undecided"
            ]

            partyRef.updateData([
                "invitees": FieldValue.arrayUnion([inviteeData])
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
                      let partyIdsHosting = userData["partyIdsHosting"] as? [String],
                      var partyIdsAttending = userData["partyIdsAttending"] as? [String] else {
                    showAlert(on: self, title: "Error", message: "Invalid user data format.")
                    return
                }
                
                if partyIdsHosting.contains(partyId) {
                    showAlert(on: self, title: "Cannot Join", message: "You are already the host of this party.")
                    return
                }
                
                if partyIdsAttending.contains(partyId) {
                    showAlert(on: self, title: "Already Joined", message: "You have already joined this party.")
                    return
                }
                
                partyIdsAttending.append(partyId)
                userRef.updateData([
                    "partyIdsAttending": partyIdsAttending,
                    "rsvps.\(partyId)": "Undecided"
                ]) { error in
                    if let error = error {
                        showAlert(on: self, title: "Error", message: "Failed to join party: \(error.localizedDescription)")
                    } else {
                        showAlert(on: self, title: "Success", message: "You have successfully joined the party!")
                        self.fetchUserParties()
                    }
                }
            }
        }
    }

}
