//
//  SecretSantaViewController.swift
//  Gatherly
//
//  Created by Samika Iyer on 3/7/25.
//

import UIKit

class SecretSantaViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDarkMode()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDarkMode()
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
