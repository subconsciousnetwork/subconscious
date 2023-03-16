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
        HStack(alignment: .center, spacing: Unit.four) {
            Button(
                action: onInsertWikilink,
                label: {
                    Image(systemName: "link")
                        .frame(
                            width: Unit.icon,
                            height: Unit.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertBold,
                label: {
                    Image(systemName: "bold")
                        .frame(
                            width: Unit.icon,
                            height: Unit.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertItalic,
                label: {
                    Image(systemName: "italic")
                        .frame(
                            width: Unit.icon,
                            height: Unit.icon
                        )
                }
            )
            Divider()
            Button(
                action: onInsertCode,
                label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .frame(
                            width: Unit.icon,
                            height: Unit.icon
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
