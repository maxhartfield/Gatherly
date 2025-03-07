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
        updateDarkMode()
        navigationController?.navigationBar.tintColor = .white

        // Custom color
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode()
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
    
    @objc func updateDarkMode() {
        if let oldGradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
                oldGradientLayer.removeFromSuperlayer()
            }
        if (darkMode){
            let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [
                    UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0).cgColor,  // Blue
                    UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0).cgColor   // Purple
                ]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.frame = view.bounds
                view.layer.insertSublayer(gradientLayer, at: 0)
        } else {
            let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [
                    UIColor(red: 255/255, green: 87/255, blue: 171/255, alpha: 1.0).cgColor,  // Pink
                    UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0).cgColor   // Orange
                ]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.frame = view.bounds
                view.layer.insertSublayer(gradientLayer, at: 0)
            
        } // Applies the correct mode
        }
    

}
