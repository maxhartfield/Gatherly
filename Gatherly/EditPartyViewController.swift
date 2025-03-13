//
//  EditPartyViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/12/25.
//

import UIKit

class EditPartyViewController: UIViewController {
    
    var party: Party?

    @IBOutlet weak var partyName: UITextField!
    @IBOutlet weak var partyDescription: UITextField!
    @IBOutlet weak var partyDate: UITextField!
    @IBOutlet weak var partyTime: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white
        partyName.text = party?.name
        partyDescription.text = party?.description
        partyDate.text = party?.date
        partyTime.text = party?.time
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
