//
//  NotFoundView.swift
//  Subconscious
//
//  Created by Ben Follington on 9/6/2023.
//

import SwiftUI

public struct NotFoundView: View {
    public var body: some View {
        VStack(spacing: AppTheme.unit * 6) {
            Spacer()
            Text("Not Found")
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
            VStack(spacing: AppTheme.unit) {
                Text("""
                     When emptiness is possible,
                     Everything is possible;
                     Were emptiness impossible,
                     Nothing would be possible.
                     """)
                .italic()
                Text(
                    "Nāgārjuna"
                )
            }
            .frame(maxWidth: 240)
            // Some extra padding to visually center the group.
            // The icon is large and rather heavy. This offset
            // helps prevent the illusion of being off-center.
            .padding(.bottom, AppTheme.unit * 24)
            .font(.caption)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.secondary)
        .background(Color.background)
        .transition(.opacity)
    }
}
