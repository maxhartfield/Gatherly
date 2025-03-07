//
//  HomeViewController.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/6/25.
//

import UIKit


class HomeViewController: UIViewController {
    
    var partyIdEntered: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode(darkMode: darkMode, to: view)
        navigationController?.navigationBar.tintColor = .white

        // Custom color
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode(darkMode: darkMode, to: view)
    }
    
    @IBAction func joinButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Join Party",
            message: "Enter Party ID",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        controller.addTextField { (textField) in
            textField.placeholder = "ex:123456"
            
        }
        
        controller.addAction(UIAlertAction(
            title: "OK",
            style: .default)
                {(action) in
            let enteredText = controller.textFields![0].text
            self.partyIdEntered = enteredText
            print(self.partyIdEntered ?? "N/A")
        })
        
        present(controller,animated:true)
    }
    

}
