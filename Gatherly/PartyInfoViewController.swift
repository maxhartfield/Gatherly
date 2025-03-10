//
//  PartyInfoViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/10/25.
//

import UIKit

class PartyInfoViewController: UIViewController {
    var party: Party?
//    let partyId: String
//    let name: String
//    let date: String
//    let time: String
//    let rsvpStatus: String
//    let isHost: Bool
    @IBOutlet weak var partyName: UILabel!
    @IBOutlet weak var partyID: UILabel!
    
    @IBOutlet weak var partyDescription: UILabel!
    
    @IBOutlet weak var partyDate: UILabel!
    
    @IBOutlet weak var partyTime: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        partyName.text = party?.name
        partyDescription.text = party?.description
        partyID.text = party?.partyId
        partyDate.text = party?.date
        partyTime.text = party?.time
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    

}
