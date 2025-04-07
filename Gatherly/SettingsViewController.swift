import UIKit
import FirebaseAuth
import FirebaseFirestore
import EventKit

var darkMode = true // CHANGE TO WHAT USER HAD STORED
var calendarEnabled = false // CHANGE TO WHAT USER HAD STORED

class SettingsViewController: UIViewController {
    
    let segueIdentifier = "LoginFromSettings"

    @IBOutlet weak var darkModeState: UISwitch!
    @IBOutlet weak var notificationsState: UISwitch!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var passwordEdit: UIButton!
    @IBOutlet weak var emailEdit: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        darkModeState.isOn = darkMode
        print(calendarEnabled)
        notificationsState.isOn = calendarEnabled
        updateDarkMode(darkMode: darkMode, to: view)
        logoutButton.tintColor = .white
        emailEdit.tintColor = .white
        passwordEdit.tintColor = .white
    }

    @IBAction func darkModePressed(_ sender: UISwitch) {
        darkMode = sender.isOn
        saveDarkModeToFirestore(darkMode: darkMode)
        updateDarkMode(darkMode: darkMode, to: view)
    }

    @IBAction func notificationsPressed(_ sender: UISwitch) {
        if sender.isOn {
            let eventStore = EKEventStore()
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        calendarEnabled = true
                        self.saveCalendarSettingToFirestore(enabled: true)
                        showAlert(on: self, title: "Calendar Access Granted", message: "You can now add parties to your calendar.")
                    } else {
                        calendarEnabled = false
                        sender.setOn(false, animated: true)
                        self.saveCalendarSettingToFirestore(enabled: false)
                        showAlert(on: self, title: "Access Denied", message: "Calendar access was not granted. Please enable it in Settings.")
                    }
                }
            }
        } else {
            calendarEnabled = false
            saveCalendarSettingToFirestore(enabled: false)
            showAlert(on: self, title: "Calendar Access Disabled", message: "Party events will no longer be added to your calendar.")
        }
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: self.segueIdentifier, sender:nil)
        } catch {
            showAlert(on: self, title:"Error", message: "Failed to log out")
        }
    }

    func saveDarkModeToFirestore(darkMode: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["darkMode": darkMode]) { error in
            if let error = error {
                showAlert(on: self, title: "Failed to update dark mode", message: "\(error.localizedDescription)")
            }
        }
    }

    func saveCalendarSettingToFirestore(enabled: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["calendarEnabled": enabled]) { error in
            if let error = error {
                showAlert(on: self, title: "Failed to update calendar setting", message: "\(error.localizedDescription)")
            }
        }
    }
}
