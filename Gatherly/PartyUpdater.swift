//
//  PartyUpdater.swift
//  Gatherly
//
//  Created by Max Hartfield on 3/12/25.
//

import Foundation

protocol PartyUpdater: AnyObject {
    func updateParty(_ updatedParty: Party)
}
