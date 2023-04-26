//
//  PetnameBylineView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Byline style for displaying a petname
struct PetnameBylineView: View {
    var petname: Petname
    private(set) var petnameColor = Color.accentColor
    
    var body: some View {
        let parts = petname.parts()

        HStack(alignment: .lastTextBaseline, spacing: 0) {
            let first = parts[0]
            
            Text(first.markup)
                // Fixed size to ensure truncation trims path preferentially
                .fixedSize(horizontal: true, vertical: false)
                .font(.callout)
                .lineLimit(1)
            
            let rest = parts[1...]
                .map { p in p.description }
                .joined(separator: ".")
            
            if rest.count > 0 {
                // Particular structure to ensure truncation trims the path and never the name
                Text(".\(rest)")
                    .font(.callout)
                    .lineLimit(1)
            }
        }
        .fontWeight(.medium)
        .foregroundColor(petnameColor)
    }
    
    func theme(
        petname petnameColor: Color = Color.accentColor
    ) -> Self {
        var this = self
        this.petnameColor = petnameColor
        return this
    }
}

struct PetnameBylineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameBylineView(
                petname: Petname("melville")!
            )
            PetnameBylineView(
                petname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])!
            )
            PetnameBylineView(
                petname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])!
            )
            .frame(maxWidth: 128)
        }
    }
}
