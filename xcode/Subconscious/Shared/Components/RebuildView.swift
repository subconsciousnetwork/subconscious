//
//  RebuildView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/22/23.
//

import SwiftUI

/// Displays information to the user when app migration / rebuild happening.
struct RebuildView: View {
    var body: some View {
        VStack {
            Text("What? Subconscious is evolving!")
                .font(.title2)
            Spacer()
            ProgressView()
            Spacer()
            Text("Upgrading database and migrating data. This could take a minute.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct RebuildView_Previews: PreviewProvider {
    static var previews: some View {
        RebuildView()
    }
}
