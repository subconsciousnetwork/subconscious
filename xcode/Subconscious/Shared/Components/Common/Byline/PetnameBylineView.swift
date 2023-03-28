//
//  PetnameBylineView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Compact byline combines a small profile pic, username, and path
struct PetnameBylineView: View {
    var petname: String
    private var petnameColor = Color.accentColor
    
    var body: some View {
        Text(verbatim: "@\(petname)")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(petnameColor)
            .lineLimit(1)
    }
    
    func theme(
        petname petnameColor: Color = Color.accentColor
    ) -> Self {
        var this = self
        this.petnameColor = petnameColor
        return this
    }
}

extension PetnameBylineView {
    init(
        petname: Petname
    ) {
        self.init(
            petname: petname.verbatim
        )
    }
    
    init(
        rawString: String
    ) {
        self.init(
            petname: rawString
        )
    }
}

struct PetnameBylineView_Previews: PreviewProvider {
    static var previews: some View {
        PetnameBylineView(
            petname: Petname("melville")!
        )
    }
}
