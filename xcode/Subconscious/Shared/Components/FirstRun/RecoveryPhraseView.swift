//
//  RecoveryPhraseView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI

struct RecoveryPhraseView: View {
    var text: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(text)
                    .monospaced()
                    .textSelection(.enabled)
                Spacer()
            }
            .padding()
            Button(
                action: {
                    UIPasteboard.general.string = text
                },
                label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy to clipboard")
                    }
                }
            )
            .buttonStyle(BarButtonStyle())
        }
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

struct RecoveryPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseView(
            text: "foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom"
        )
    }
}
