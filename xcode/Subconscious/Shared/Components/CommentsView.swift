//
//  CommentsView.swift
//  Subconscious
//
//  Created by Ben Follington on 13/2/2024.
//

import SwiftUI

struct CommentsView: View {
    var comments: [String]
    var onRefresh: () -> Void
    var onRespond: (_ comment: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            Button(
                action: {
                    onRefresh()
                },
                label: {
                    HStack {
                        Text("Comments")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            )
            .foregroundStyle(.secondary)
            
            if comments.count > 0 {
                LazyVStack(alignment: .leading, spacing: AppTheme.unit) {
                    ForEach(comments, id: \.self) { comment in
                        Button(
                            action: { onRespond(comment) },
                            label: {
                                Text("\(comment)")
                                    .italic()
                                    .multilineTextAlignment(.leading)
                            }
                        )
                        .padding(.horizontal, AppTheme.unit3)
                        .padding(.vertical, AppTheme.unit2)
                        .foregroundStyle(.primary)
                        .background(comment.themeColor.toColor())
                        .cornerRadius(AppTheme.cornerRadiusLg, corners: .allCorners)
                        .shadow(style: .transclude)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.unit4)
        .padding(.vertical, AppTheme.unit2)
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CommentsView(
                
                comments: [
                    "This is a comment",
                    "This is another comment"
                ],
                onRefresh: { },
                onRespond: { _ in }
            )
        }
    }
}
