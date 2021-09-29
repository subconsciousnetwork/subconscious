//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

struct SuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case .entry(let text):
            Label(
                title: {
                    HStack {
                        Text(text)
                        Text("— Open")
                            .foregroundColor(Color.secondaryText)
                    }
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).lineLimit(1)
        case .search(let text):
            Label(
                title: {
                    HStack {
                        Text(text)
                        Text("— Create")
                            .foregroundColor(Color.secondaryText)
                    }
                },
                icon: {
                    Image(systemName: "magnifyingglass")
                }
            ).lineLimit(1)
        }
    }
}

struct SuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionLabelView(
            suggestion: .search("Floop the pig")
        )
    }
}
