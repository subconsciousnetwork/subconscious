//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/23/22.
//

import SwiftUI

struct TranscludeView: View {
    var pfp: Image
    var petname: String
    var slug: String
    var title: String
    var excerpt: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            BylineSmView(
                pfp: pfp,
                petname: petname,
                slug: slug
            )
            HStack {
                Text(title)
                    .bold()
                Spacer()
            }
            Text(excerpt)
        }
        .padding(.vertical, AppTheme.unit3)
        .padding(.horizontal, AppTheme.unit4)
        .overlay(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadiusLg
            )
            .stroke(Color.separator, lineWidth: 1)
        )
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeView(
            pfp: Image("dog-pfp"),
            petname: "@doge",
            slug: "/thoughts",
            title: "Thoughts of Doge",
            excerpt: "Food food park park park run run play run fetch ball run water shlorp shlorp shlorp dog bork bork bork home sleep sleep dream sleep"
        )
    }
}
