//
//  SecretSantaViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/7/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SecretSantaViewController: UIViewController {
    var party: Party?
    @IBOutlet weak var wishlistItem3: UITextField!
    @IBOutlet weak var wishlistItem2: UITextField!
    @IBOutlet weak var wishlistItem1: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        // Do any additional setup after loading the view.
        
        let partyId = party!.partyId
                
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("parties").document(partyId)
            .collection("wishlists").document(currentUserID).getDocument {
                doc, error in
                
                if let error = error {
                    print("Error fetching wishlist: \(error.localizedDescription)")
                } else if let data = doc?.data() {
                    let wishlist = data["wishlist"] as? [String]
                    self.wishlistItem1.text = wishlist![0]
                    self.wishlistItem2.text = wishlist![1]
                    self.wishlistItem3.text = wishlist![2]
                }
            }
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    
    @IBAction func submitPressed(_ sender: Any) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        guard let party = party else { return }
        
        let item1 = wishlistItem1.text ?? ""
        let item2 = wishlistItem2.text ?? ""
        let item3 = wishlistItem3.text ?? ""

        let wishlistItems = [item1, item2, item3].filter { !$0.isEmpty }
        let wishlistData: [String: Any] = [
            "wishlist": wishlistItems,
            "timestamp": FieldValue.serverTimestamp()
        ]
                
        let db = Firestore.firestore()
        db.collection("parties").document(party.partyId)
            .collection("wishlists").document(currentUserID)
            .setData(wishlistData) { error in
                if let error = error {
                    print("Error saving wishlist: \(error)")
                } else {
                    print("Wishlist saved successfully!")
                    self.navigationController?.popViewController(animated: true)
                }
            }

        
        self.navigationController?.popViewController(animated: true)

    }
}

