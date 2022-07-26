//
//  StoryView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import SwiftUI

/// A story is a single update within the FeedView
struct StoryView: View {
    var entry: SubtextFile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("@cdata")
                Text("posted at")
                    .foregroundColor(Color.secondary)
                Text(entry.modified().formatted())
                    .foregroundColor(Color.secondary)
                Spacer()
            }
            .font(Font(UIFont.appTextSmall))
            .padding()
            .frame(height: AppTheme.unit * 11)
            Divider()
            VStack {
                Text("Hello World")
            }
            .padding()
            Divider()
            HStack {
                Button(
                    action: {},
                    label: {
                        Text("Open")
                    }
                )
                Spacer()
            }
            .padding()
            .frame(height: AppTheme.unit * 15)
            ThickDividerView()
        }
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView(
            entry: SubtextFile(
                slug: Slug("example")!,
                content: """
                Content-Type: text/subtext
                Title: Example post

                Example
                """
            )
        )
    }
}
