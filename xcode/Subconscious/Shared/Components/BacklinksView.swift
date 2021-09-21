//
//  BacklinksView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct BacklinksView: View {
    var backlinks: [TextFile]
    var onActivateBacklink: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(backlinks) { entry in
                Button(
                    action: {
                        onActivateBacklink(entry.title)
                    },
                    label: {
                        HStack {
                            Text(entry.title)
                                .bold()
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(AppTheme.padding)
                    }
                )
                .contentShape(Rectangle())
                .cornerRadius(AppTheme.cornerRadius)
                .background(Color.background)
            }
        }
    }
}

struct BacklinksView_Previews: PreviewProvider {
    static var previews: some View {
        BacklinksView(
            backlinks: [
                TextFile(
                    url: URL(fileURLWithPath: "Example.subtext"),
                    content: """
                    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
                    """
                )
            ],
            onActivateBacklink: { title in }
        )
    }
}
