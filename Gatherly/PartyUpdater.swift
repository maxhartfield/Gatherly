//
//  PartyUpdater.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/12/25.
//

import Foundation
import FirebaseFirestore

protocol PartyUpdater: AnyObject {
    func updateParty(_ updatedParty: Party)
}

extension PartyUpdater {

    func assignSecretSantaPairs(for participantIDs: [String]) -> [String: String] {
        guard participantIDs.count > 1 else {
            print("Not enough participants for Secret Santa.")
            return [:]
        }
        
        let shuffledParticipants = participantIDs.shuffled()
        var assignments: [String: String] = [:]
        
        for index in 0..<shuffledParticipants.count {
            let giver = shuffledParticipants[index]
            let receiver = shuffledParticipants[(index + 1) % shuffledParticipants.count]
            assignments[giver] = receiver
        }
        
        return assignments
    }
    
    func updatePartyAssignments(partyId: String, assignments: [String: String], completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        db.collection("parties").document(partyId)
            .updateData(["assignments": assignments]) { error in
                if let error = error {
                    print("Error updating assignments: \(error.localizedDescription)")
                } else {
                    print("Assignments updated successfully.")
                }
                completion?(error)
            }
    }
}
