//
//  AppUpgradeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/22/23.
//

import SwiftUI

/// Displays information to the user when app migration / rebuild happening.
struct AppUpgradeView: View {
    var body: some View {
        VStack {
            Text("What? Subconscious is evolving!")
                .font(.title2)
            Spacer()
            ProgressView() {
                VStack(spacing: AppTheme.unit) {
                    Text("Upgrading database.")
                    Text("This could take a minute.")
                }
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
    }
}

struct AppUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        AppUpgradeView()
    }
}
