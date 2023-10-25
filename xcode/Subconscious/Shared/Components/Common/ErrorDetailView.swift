//
//  ErrorDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI

struct ErrorDetailView: View {
    var title = String(localized: "Issue Details")
    var error: String
    var errorMaxHeight: CGFloat = 80
    @Binding var isExpanded: Bool
    
    var body: some View {
        DisclosureGroup(title, isExpanded: $isExpanded) {
            ScrollView {
                Text(error)
                    .font(.caption.monospaced())
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }
            .expandAlignedLeading()
            .frame(maxHeight: errorMaxHeight)
            .padding(AppTheme.tightPadding)
            .foregroundColor(.primary)
            .background(Color.secondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .padding([.top], AppTheme.unit2)
        }
        .tint(.secondary)
    }
}

struct ErrorDetailView_Previews: PreviewProvider {
    
    struct TestView: View {
        @State private var isExpanded = false
        var error: String
        var body: some View {
           ErrorDetailView(error: error, isExpanded: $isExpanded)
        }
    }
    
    static var previews: some View {
        TestView(
            error: ""
        )
        TestView(
            error: "This is a test error with a longunbrokenstringtotestwrappingbehaviorofthetextbox The skilful traveller leaves no traces of his wheels or footsteps; the skilful speaker says nothing that can be found fault with or blamed; the skilful reckoner uses no tallies; the skilful closer needs no bolts or bars, while to open what he has shut will be impossible; the skilful binder uses no strings or knots, while to unloose what he has bound will be impossible."
        )
    }
}
