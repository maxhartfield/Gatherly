//
//  User.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/10/25.
//

import Foundation

struct User {
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    let rsvps: [String: String]
    var bringing : [String : [String]]?
    let darkMode: Bool
    let calendarEnabled: Bool
}
