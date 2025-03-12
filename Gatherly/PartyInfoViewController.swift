//
//  PartyInfoViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/10/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth


class PartyInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var party: Party?
    var invitees: [User] = []
    var rsvps : [String : String] = [:]
    @IBOutlet weak var partyName: UILabel!
    @IBOutlet weak var partyID: UILabel!
    @IBOutlet weak var partyDescription: UILabel!
    @IBOutlet weak var partyDate: UILabel!
    @IBOutlet weak var partyTime: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rsvpSelector: UISegmentedControl!
    
    
    let cellIdentifier = "InviteeCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        partyName.text = party?.name
        partyDescription.text = party?.description
        partyID.text = party?.partyId
        partyDate.text = party?.date
        partyTime.text = party?.time
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        fetchInvitees()
        initRsvp()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    @IBAction func rsvpChanged(_ sender: Any) {
        switch rsvpSelector.selectedSegmentIndex {
            case 0 :
                // "Going"
                setRsvp(new: "Going")
            case 1 :
                // "Not Going
                setRsvp(new: "Not Going")
            case 2 :
                // "Undecided"
                setRsvp(new: "Undecided")
            default:
                print("Problem with RSVP Selector")
        }
        
    }
    
    func initRsvp() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }
        
        let partyId = party!.partyId
        
        Firestore.firestore().collection("parties").document(partyId).getDocument { partyDoc, error in
            if let error = error {
                print("Error fetching party \(partyId): \(error.localizedDescription)")
                return
            }
            if let partyData = partyDoc?.data(),
               let hostUid = partyData["hostUid"] as? String {
                if (hostUid == uid) {
                    self.rsvpSelector.isHidden = true
                }
            }

        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { document, error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                let rsvpStatus = data["rsvps"] as? [String : String] else {
                showAlert(on: self, title: "Error", message: "Invalid user data format.")
                return
            }
            self.rsvps = rsvpStatus
            
            switch rsvpStatus[self.party!.partyId] {
            case "Going":
                self.rsvpSelector.selectedSegmentIndex = 0
            case "Not Going":
                self.rsvpSelector.selectedSegmentIndex = 1
            case "Undecided":
                self.rsvpSelector.selectedSegmentIndex = 2
            default:
                self.rsvpSelector.selectedSegmentIndex = 2
            }
            
        }
    }
    
    func setRsvp(new : String){
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(on: self, title: "Error", message: "No user logged in.")
            return
        }
        
        self.rsvps[self.party!.partyId] = new
        

        let db = Firestore.firestore()
        
        db.collection("users").document(uid).updateData([
            "rsvps" : self.rsvps
        ]) { error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to update RSVP: \(error.localizedDescription)")
            } else {
                print("Updated RSVP to \(new)")
            }
        }
        fetchInvitees()
        self.tableView.reloadData()
    }
    
    func fetchInvitees() {
         guard let party = party else { return }
         let db = Firestore.firestore()
         
         invitees.removeAll()
         let group = DispatchGroup()
         for uid in party.invitees {
             group.enter()
             let userRef = db.collection("users").document(uid)
             
             userRef.getDocument { (document, error) in
                 defer { group.leave() }
                 
                 if let error = error {
                     print("Error fetching user \(uid): \(error.localizedDescription)")
                     return
                 }
                 
                 if let data = document?.data(),
                    let firstName = data["firstName"] as? String,
                    let lastName = data["lastName"] as? String,
                    let email = data["email"] as? String,
                    let rsvps = data["rsvps"] as? [String: String],
                    let darkMode = data["darkMode"] as? Bool {
                     
                     let user = User(uid: uid, firstName: firstName, lastName: lastName, email: email, rsvps: rsvps, darkMode: darkMode)
                     self.invitees.append(user)
                 }
             }
         }
         
         group.notify(queue: .main) {
             self.invitees.sort { $0.lastName < $1.lastName }
             self.tableView.reloadData()
         }
     }
     
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return invitees.count
     }
     
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
         let user = invitees[indexPath.row]
         cell.textLabel?.text = "\(user.firstName) \(user.lastName)"
         cell.textLabel?.textColor = .white
         cell.contentView.backgroundColor = .systemGray
         
         let rsvpStatus = user.rsvps[party?.partyId ?? ""] ?? "Undecided"
         
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
         
         return cell
     }

}
