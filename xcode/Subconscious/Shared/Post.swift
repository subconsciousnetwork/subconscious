//
//  Post.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//

import SwiftUI

struct PostState {
    var thread: ThreadModel
}

/// PostViews are threads wrapped in information about who/where the thread is from.
struct PostView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
    }
}
