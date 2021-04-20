//
//  ResultsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

struct SearchView: View {
    @Binding var threads: [Thread]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ThreadListView(threads: threads)
            }
            .padding(.top, 4)
        }
    }
}

//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView(
//        )
//    }
//}
