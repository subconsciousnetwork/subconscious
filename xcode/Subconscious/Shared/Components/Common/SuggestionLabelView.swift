//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI
import OrderedCollections

enum Suggestion: Hashable, CustomStringConvertible {
    case entry(Stub)
    case search(Stub)

    var description: String {
        switch self {
        case let .entry(stub):
            return stub.title
        case let .search(stub):
            return stub.title
        }
    }
}

struct SuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    VStack {
                        Text(stub.title)
                            .foregroundColor(Color.text)
                        Text(stub.slug)
                            .foregroundColor(Color.secondaryText)
                    }
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).lineLimit(1)
        case let .search(stub):
            Label(
                title: {
                    VStack {
                        Text(stub.title)
                            .foregroundColor(Color.text)
                        Text("New note")
                            .foregroundColor(Color.secondaryText)
                    }
                },
                icon: {
                    Image(systemName: "doc.badge.plus")
                }
            ).lineLimit(1)
        }
    }
}

// A second label view that does not include the action label
struct SuggestionLabelView2: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    VStack {
                        Text(stub.title)
                            .foregroundColor(Color.text)
                        Text(stub.slug)
                            .foregroundColor(Color.secondaryText)
                    }
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).lineLimit(1)
        case let .search(stub):
            Label(
                title: {
                    HStack {
                        Text(stub.title)
                            .foregroundColor(Color.text)
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
            suggestion: .search(
                Stub(title: "Floop the pig")
            )
        )
    }
}
