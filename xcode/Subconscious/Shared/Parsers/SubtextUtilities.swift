//
//  SubtextUtilities.swift
//  Domain-specific extensions to Subtext.
//  Subconscious
//
//  Created by Gordon Brander on 12/5/23.
//

import Foundation

extension Subtext {
    /// Read all valid slashlinks from DOM as an array of `Slashlink`.
    var parsedSlashlinks: [Subconscious.Slashlink] {
        slashlinks.compactMap({ subtextSlashlink in
            Subconscious.Slashlink(String(describing: subtextSlashlink))
        })
    }
}
