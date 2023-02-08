//
//  ToolbarTitleGroupView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//

import SwiftUI

struct ToolbarTitleGroupView: View, Equatable {
    var title: Text
    var subtitle: Text

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: AppTheme.unit) {
                title
                    .foregroundColor(Color.text)
                    .frame(height: AppTheme.textSize)
                    .lineLimit(1)
                subtitle
                    .font(.caption)
                    .frame(height: AppTheme.captionSize)
                    .foregroundColor(Color.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}

struct ToolbarTitleGroupView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarTitleGroupView(
            title: Text("Floop"),
            subtitle: Text("floop")
        )
    }
}
