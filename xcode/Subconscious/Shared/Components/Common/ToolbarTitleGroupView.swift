//
//  ToolbarTitleGroupView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//

import SwiftUI

struct ToolbarTitleGroupView: View {
    var title: String
    var slug: Slug?
    var untitled = "Untitled"
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: AppTheme.unit) {
                Text(title.isEmpty ? untitled : title)
                    .font(Font(UIFont.appText))
                    .foregroundColor(Color.text)
                    .frame(height: AppTheme.textSize)
                    .lineLimit(1)
                Text(slug?.description ?? untitled)
                    .font(Font(UIFont.appCaption))
                    .frame(height: AppTheme.captionSize)
                    .foregroundColor(Color.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}

struct ToolbarTitleGroupView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarTitleGroupView(
            title: "Floop",
            slug: Slug("floop")
        )
    }
}
