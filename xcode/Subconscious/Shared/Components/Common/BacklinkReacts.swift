//
//  BacklinkReacts.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/12/23.
//

import SwiftUI

/// Displays backlink react bar, including link icon, PFPs, and count.
struct BacklinkReacts<Data, Content>: View
where
    Data: RandomAccessCollection,
    Content: Identifiable,
    Data.Element == Content
{
    var data: Data
    var content: (Content) -> Image

    var body: some View {
        HStack {
            Image(systemName: "link")
                .foregroundColor(.secondary)
            HStack(spacing: -8) {
                ForEach(data.prefix(6)) { element in
                    ProfilePicSm(image: content(element))
                }
            }
            Text("\(data.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BacklinkReacts_Previews: PreviewProvider {
    static var previews: some View {
        BacklinkReacts(
            data: [
                Slug("a")!,
                Slug("b")!,
                Slug("c")!,
                Slug("d")!,
                Slug("e")!,
                Slug("f")!,
                Slug("g")!,
                Slug("h")!,
            ]
        ) { element in
            Image("pfp-dog")
        }
    }
}
