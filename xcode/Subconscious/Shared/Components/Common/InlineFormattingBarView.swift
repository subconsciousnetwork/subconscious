//
//  InlineFormattingBarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/20/22.
//

import SwiftUI

struct InlineFormattingBarView: View {
    var onInsertWikilink: () -> Void
    var onInsertBold: () -> Void
    var onInsertItalic: () -> Void
    var onInsertCode: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.unit4) {
            Button(
                action: onInsertWikilink,
                label: {
                    Image(systemName: "link")
                        .frame(
                            width: AppTheme.icon,
                            height: AppTheme.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertBold,
                label: {
                    Image(systemName: "bold")
                        .frame(
                            width: AppTheme.icon,
                            height: AppTheme.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertItalic,
                label: {
                    Image(systemName: "italic")
                        .frame(
                            width: AppTheme.icon,
                            height: AppTheme.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertCode,
                label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .frame(
                            width: AppTheme.icon,
                            height: AppTheme.icon
                        )
                }
            )
        }
    }
}

struct InlineFormattingBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InlineFormattingBarView(
                onInsertWikilink: {},
                onInsertBold: {},
                onInsertItalic: {},
                onInsertCode: {}
            )
            Spacer()
        }
    }
}
