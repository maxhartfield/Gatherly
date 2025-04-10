//
//  PartyInfoViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/10/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth


class PartyInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PartyUpdater {
    
    var party: Party?
    var invitees: [User] = []
    var rsvps : [String : String] = [:]
    @IBOutlet weak var partyName: UILabel!
    
    
    @IBOutlet weak var partyID: UITextView!
    
    
    @IBOutlet weak var partyDescription: UILabel!
    @IBOutlet weak var partyDate: UILabel!
    @IBOutlet weak var partyTime: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rsvpSelector: UISegmentedControl!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // potluck
    @IBOutlet weak var addItemsButton: UIButton!
    @IBOutlet weak var createListButton: UIButton!
    
    // secret santa
    @IBOutlet weak var assignButton: UIButton!
    @IBOutlet weak var createWishlistButton: UIButton!
    @IBOutlet weak var viewWishlistButton: UIButton!
    
    let cellIdentifier = "InviteeCell"
    let segueToEdit = "EditParty"
    
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
        
        // secret santa
        viewWishlistButton.isHidden = true
        createWishlistButton.isHidden = true
        
        // potluck
        addItemsButton.isHidden = true
        createListButton.isHidden = true
        
        assignButton.isHidden = true
        if let partyType = party?.partyType, partyType == "Secret Santa"{
            view.backgroundColor = UIColor(red: 0.95, green: 0.88, blue: 0.73, alpha: 1.0)
            viewWishlistButton.isHidden = false
            createWishlistButton.isHidden = false
        }
        if let partyType = party?.partyType, partyType == "Potluck"{
            addItemsButton.isHidden = false
        }
        fetchInvitees()
        initRsvp()
        
        // add calendar if you haven't
//        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//        Firestore.firestore().collection("users").document(currentUserID).updateData([
//            "calendarEnabled" : false
//        ]) { error in
//            if let error = error {
//                showAlert(on: self, title: "Firestore Error", message: "Failed to save user: \(error.localizedDescription)")
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }

    
    @IBAction func receiverWishlistPressed(_ sender: Any) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        guard let receiverUID = party?.assignments?[currentUserID] else {
            showAlert(on: self, title: "No Assignment", message: "You haven't been assigned a recipient yet.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(receiverUID)

        userRef.getDocument { userDoc, error in
            if let error = error {
                showAlert(on: self, title: "Error", message: "Failed to fetch recipient's name: \(error.localizedDescription)")
                return
            }

            guard let userData = userDoc?.data(),
                  let firstName = userData["firstName"] as? String,
                  let lastName = userData["lastName"] as? String else {
                showAlert(on: self, title: "Error", message: "Could not find recipient's name.")
                return
            }

            let recipientName = "\(firstName) \(lastName)"
            db.collection("parties").document(self.party!.partyId)
                .collection("wishlists").document(receiverUID)
                .getDocument { document, error in
                    if let error = error {
                        let message = "Failed to fetch wishlist"
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                        return
                    }

                    var message: String
                    if let document = document, document.exists,
                       let data = document.data() {
                        if let wishlistItems = data["wishlist"] as? [String] {
                            message = wishlistItems.joined(separator: "\n")
                        } else if let wishlistText = data["wishlist"] as? String {
                            message = wishlistText
                        } else {
                            message = "No wishlist items found."
                        }
                    } else {
                        message = "Your recipient hasn't submitted a wishlist yet."
                    }

                    let alert = UIAlertController(title: "\(recipientName)'s Wishlist", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                }
        }
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
    
    @IBAction func assignPressed(_ sender: Any) {
        guard let party = self.party else { return }
        let db = Firestore.firestore()
        let partyId = party.partyId
        let invitees = party.invitees
        var goingInvitees: [String] = []
        let dispatchGroup = DispatchGroup()

        for uid in invitees {
            dispatchGroup.enter()
            let userRef = db.collection("users").document(uid)
            userRef.getDocument { (doc, error) in
                defer { dispatchGroup.leave() }

                if let error = error {
                    print("Error fetching user: \(error.localizedDescription)")
                    return
                }
                if let data = doc?.data(),
                   let rsvps = data["rsvps"] as? [String: String],
                   rsvps[partyId] == "Going" {
                    goingInvitees.append(uid)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            let assignments = self.assignSecretSantaPairs(for: goingInvitees)
            self.party?.assignments = assignments
            self.updatePartyAssignments(partyId: partyId, assignments: assignments) { error in
                if error == nil {
                    let alert = UIAlertController(
                        title: "Success!",
                        message: "Secret Santa Pairs have been assigned!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                } else {
                    showAlert(on: self, title: "Error", message: "Failed to update assignments.")
                }
            }
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
                    if (self.party?.partyType == "Secret Santa") {
                        self.assignButton.isHidden = false
                    }
                    if (self.party?.partyType == "Potluck") {
                        self.createListButton.isHidden = false
                    }
                } else {
                    self.editButton.isHidden = true
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
                    let darkMode = data["darkMode"] as? Bool,
                    let calendarEnabled = data["calendarEnabled"] as? Bool {
                     let user = User(uid: uid, firstName: firstName, lastName: lastName, email: email, rsvps: rsvps, darkMode: darkMode, calendarEnabled: calendarEnabled)
                     self.invitees.append(user)
                 }
             }
         }
         
         self.tableView.reloadData()
         
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditParty" {
            if let editPartyVC = segue.destination as? EditPartyViewController {
                editPartyVC.party = self.party
                editPartyVC.delegate = self
            }
        } else if segue.identifier == "SecretSanta" {
            if let secretSantaVC = segue.destination as? SecretSantaViewController {
                secretSantaVC.party = self.party
            }
        } else if segue.identifier == "Potluck" {
            if let potluckVC = segue.destination as? PotluckWishlistViewController {
                potluckVC.party = self.party
                potluckVC.delegate = self
            }
        } else if segue.identifier == "PotluckList"{
            if let potlucklistVC = segue.destination as? CreateListViewController {
                potlucklistVC.party = self.party
                potlucklistVC.delegate = self
            }
        }
    }

    func updateParty(_ updatedParty: Party) {
        self.party = updatedParty
        self.partyName.text = updatedParty.name
        self.partyDescription.text = updatedParty.description
        self.partyDate.text = updatedParty.date
        self.partyTime.text = updatedParty.time
    }
}
