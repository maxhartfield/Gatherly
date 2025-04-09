//
//  PotluckWishlistViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/7/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class bringingCell : UITableViewCell {
    @IBOutlet weak var bringingLabel: UILabel!
    @IBOutlet weak var bringingPerson: UILabel!
    
}

class othersCell : UITableViewCell {
    @IBOutlet weak var otherLabel: UILabel!
}


class PotluckWishlistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var party : Party?
    @IBOutlet weak var bringingTable: UITableView!
    @IBOutlet weak var othersTable: UITableView!
    var delegate : UIViewController!
    var bringing : [String] = []
    var others : [String] = []
    var claimed : [String : Bool] = [:]
    var mappings : [String : String] = [:]
    
    var namemappings : [String : String] = [:]
    var nameids : [String : String] = [:]
    
    @IBOutlet weak var textBox: UITextField!
    
    var uid : String = ""
    
    let cellIDBringing = "bringingCell"
    let cellIDOthers = "othersCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        
        bringingTable.delegate = self
        bringingTable.dataSource = self
        othersTable.dataSource = self
        othersTable.delegate = self
        bringingTable.isScrollEnabled = true
        othersTable.isScrollEnabled = true
        
        fetchData()
        // Do any additional setup after loading the view.
    }
    
    func fetchData() {
        
        self.uid = Auth.auth().currentUser!.uid
        self.nameids[uid] = "Me"
        print("uid is \(self.uid)")
        
        let db = Firestore.firestore()
        db.collection("parties").document(party!.partyId).getDocument { (document, error) in
            
            let data = document!.data()
            
            let dataitems = data!["items"] as? [String] ?? []
            let dataclaimed = data!["claimed"] as? [String : Bool] ?? [:]
            let datamappings = data!["mappings"] as? [String : String] ?? [:]
            
            self.claimed = dataclaimed
            self.mappings = datamappings
            
            for temp in dataitems {
                if self.claimed[temp] == true {
                    self.bringing.append(temp)
                } else {
                    self.others.append(temp)
                }
            }
            
            for (key, value) in datamappings {
                
                var returnString : String = ""
                
                if value == self.uid {
                    self.namemappings[key] = "Me"
                    continue
                }
                
                let userRef = Firestore.firestore().collection("users").document(value)
                userRef.getDocument { document, error in
                    if let error = error {
                        showAlert(on: self, title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = document?.data() else {
                        showAlert(on: self, title: "Error", message: "Invalid user data format.")
                        return
                    }
                    
                    let firstname = data["firstName"] as! String
                    let lastname = data["lastName"] as! String
                    self.namemappings[key] = "\(firstname) \(lastname)"
                    self.othersTable.reloadData()
                    self.bringingTable.reloadData()
                }
                
            }
            
            
            self.othersTable.reloadData()
            self.bringingTable.reloadData()
        }        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // update...
        
        let newItemList = bringing + others
        let newClaimed = claimed
        let newMapping = mappings
        
        print(newMapping)
        let potluckData: [String: Any] = [
            "items": newItemList,
            "claimed" : newClaimed,
            "mappings" : newMapping
        ]
            
        let db = Firestore.firestore()
        db.collection("parties").document(party!.partyId).updateData(potluckData) { error in
            if let error = error {
                print("Error saving potluck: \(error)")
            } else {
                print("Potluck List Saved!!")
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == bringingTable {
            return bringing.count
        } else {
            return others.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == bringingTable {
            let cell = bringingTable.dequeueReusableCell(withIdentifier: cellIDBringing, for: indexPath) as! bringingCell
            cell.bringingLabel.text = bringing[indexPath.row]
            cell.bringingPerson.text = "by \(self.namemappings[bringing[indexPath.row]] ?? "unkown")"
            return cell
        } else {
            let cell = othersTable.dequeueReusableCell(withIdentifier: cellIDOthers, for: indexPath) as! othersCell
            cell.otherLabel.text = others[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == bringingTable {
            
            let id = mappings[bringing[indexPath.row]]
            
            if id == self.uid {
                let itemToDel = bringing[indexPath.row]
                bringing.remove(at: indexPath.row)
                others.append(itemToDel)
                mappings.removeValue(forKey: itemToDel)
                namemappings.removeValue(forKey: itemToDel)
                claimed[itemToDel] = false
                othersTable.reloadData()
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                showAlert(on: self, title: "Error", message: "Please only change items you have signed up for.")
            }

        } else {
            let itemToDel = others[indexPath.row]
            others.remove(at: indexPath.row)
            bringing.append(itemToDel)
            claimed[itemToDel] = true
            mappings[itemToDel] = self.uid
            namemappings[itemToDel] = "Me"
            bringingTable.reloadData()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        if textBox.text! == "" {
            showAlert(on: self, title: "Error", message: "Type an item to bring")
        } else {
            let item = textBox.text!
            
            others.append(item)
            claimed[item] = false
            othersTable.reloadData()
            textBox.text = ""
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == othersTable {
            if editingStyle == .delete {
                let itemToDel = others[indexPath.row]
                others.remove(at: indexPath.row)
                claimed.removeValue(forKey: itemToDel)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    
}
