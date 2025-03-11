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
                       let hostUid = partyData["hostUid"] as? String {
                        let isHost = (hostUid == uid)
                        let invitees = partyData["invitees"] as? [String]
                        let party = Party(partyId: partyId, name: name, description: description, date: dateString, time: time, invitees: invitees ?? [], hostUid: hostUid)
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
        cell.textLabel?.text = "\(party.name)     Date: \(party.date) at \(party.time)"
        cell.detailTextLabel?.textColor = .white
        guard let user = Auth.auth().currentUser else { return cell }
        let uid = user.uid
        let db = Firestore.firestore()
        cell.detailTextLabel?.text = party.hostUid == uid ? "Host" : "Invitee"
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { (document, error) in
            DispatchQueue.main.async {
                if let document = document, document.exists,
                   let rsvps = document.data()?["rsvps"] as? [String: String],
                   let rsvpStatus = rsvps[party.partyId] {
                    switch rsvpStatus {
                    case "Going":
                        cell.contentView.backgroundColor = .systemGreen
                    case "Undecided":
                        cell.contentView.backgroundColor = .systemYellow
                    case "Not Going":
                        cell.contentView.backgroundColor = .systemRed
                    default:
                        cell.contentView.backgroundColor = .systemGray
                    }
                } else {
                    showAlert(on: self, title: "Error:", message: "No RSVP found for party \(party.partyId)")
                }
            }
        }
        return cell
    }


        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PartyInfoSegue" {
            if let destinationVC = segue.destination as? PartyInfoViewController,
               let indexPath = tableView.indexPathForSelectedRow {
                let selectedParty = parties[indexPath.row]
                destinationVC.party = selectedParty
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
                    }
                }
            }
        }
    }

}
