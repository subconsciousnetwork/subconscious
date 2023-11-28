//
//  ArrayUtilities.swift
//  Subconscious
//
//  Created by Ben Follington on 22/11/2023.
//

import Foundation

extension Array {
    mutating func insertAtRandomIndex(_ item: Element, skippingFirst skipCount: Int) {
        // Calculate the starting index for the random range
        let startIndex = self.count < skipCount ? 0 : skipCount
        // Ensure the end index is at least equal to the start index
        let endIndex = Swift.max(startIndex, self.count)
        let range = startIndex..<endIndex
        
        if (range.isEmpty) {
            self.append(item)
            return
        }
        
        // Generate a random index within the range
        let randomIndex = Int.random(in: range)
        self.insert(item, at: randomIndex)
    }
}
