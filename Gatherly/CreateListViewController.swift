//
//  CreateListViewController.swift
//  Gatherly
//
//  Created by Raymond Wang on 4/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class itemListCell : UITableViewCell {
    @IBOutlet weak var itemLabel: UILabel!
}

class CreateListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var itemlist : [String] = []
    var claimedlist : [String : Bool] = [:]
    var mappinglist : [String : String] = [:]
    
    let cellID = "itemCell"
    var delegate : UIViewController!
    var party : Party!
    
    

    @IBOutlet weak var ItemListTable: UITableView!
    @IBOutlet weak var TextBox: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        ItemListTable.dataSource = self
        ItemListTable.delegate = self
        fetchData()
        // Do any additional setup after loading the view.
    }
    
    func fetchData() {
        let db = Firestore.firestore()
        db.collection("parties").document(party!.partyId).getDocument { (document, error) in
            
            let data = document!.data()
            if let templist = data!["items"], let tempclaims = data!["claimed"] {
                // found previous
                print("found previous")
                
                self.itemlist = templist as! [String]
                self.claimedlist = tempclaims as! [String : Bool]
                
               
                if let tempmaps = data!["mappings"] {
                    self.mappinglist = tempmaps as! [String : String]
                    print(tempmaps)

                }
                self.ItemListTable.reloadData()
            }
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        let otherVC = delegate as! PartyInfoViewController
//        otherVC.initPotluck(items: itemlist)
        
        let potluckData: [String: Any] = [
            "items": itemlist,
            "claimed" : claimedlist,
            "mappings" : mappinglist
        ]
            
        print(potluckData)
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
        return itemlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = ItemListTable.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! itemListCell
        cell.itemLabel.text = itemlist[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // delete from data, claimed, and mappings
            let itemToDel = itemlist[indexPath.row]
            itemlist.remove(at: indexPath.row)
            claimedlist.removeValue(forKey: itemToDel)
            mappinglist.removeValue(forKey: itemToDel)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    @IBAction func addPressed(_ sender: Any) {
        if TextBox.text != "" {
            itemlist.append(TextBox.text!)
            claimedlist[TextBox.text!] = false
            ItemListTable.reloadData()
            print("adding \(TextBox.text!)")
        }
        TextBox.text = ""
    }
    
    

}
