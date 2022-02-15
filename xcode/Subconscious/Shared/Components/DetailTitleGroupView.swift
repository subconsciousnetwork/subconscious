//
//  DetailTitleGroupView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//

import SwiftUI

struct DetailTitleGroupView: View {
    var title: String
    var slug: Slug?
    var body: some View {
        VStack(spacing: AppTheme.unit) {
            Text(title.isEmpty ? "Untitled" : title)
                .font(Font(UIFont.appText))
                .foregroundColor(Color.text)
                .frame(height: AppTheme.textSize)
            Text(slug?.description ?? "untitled")
                .font(Font(UIFont.appCaption))
                .frame(height: AppTheme.captionSize)
                .foregroundColor(Color.secondaryText)
        }
    }
}

struct DetailTitleGroupView_Previews: PreviewProvider {
    static var previews: some View {
        DetailTitleGroupView(
            title: "Floop",
            slug: Slug("floop")
        )
    }
}
