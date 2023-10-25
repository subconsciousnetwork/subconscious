//
//  ErrorDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI

struct ErrorDetailView: View {
    var error: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        DisclosureGroup("Debug Details", isExpanded: $isExpanded) {
            ScrollView {
                Text(error)
                    .font(.caption.monospaced())
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .frame(idealHeight: 24, maxHeight: 128)
            }
            .expandAlignedLeading()
            .padding(AppTheme.tightPadding)
            .foregroundColor(.secondary)
            .background(Color.secondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .padding([.top], AppTheme.unit2)
        }
    }
}

struct ErrorDetailView_Previews: PreviewProvider {
    
    struct TestView: View {
        @State var isExpanded = false
        var body: some View {
           ErrorDetailView(error: "This is a test error", isExpanded: $isExpanded)
        }
    }
    
    static var previews: some View {
        TestView()
    }
}
