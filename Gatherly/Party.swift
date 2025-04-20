//
//  Party.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/7/25.
//

import Foundation

struct Party {
    var partyId: String
    var name: String
    var description: String
    var date: String
    var time: String
    var partyType: String
    var invitees: [String]
    var hostUid: String
    var assignments: [String: String]?
    var potlucklist : [String: Bool]?
    var calendarEventId: String?
    var userRSVPStatus: String? = nil
}
