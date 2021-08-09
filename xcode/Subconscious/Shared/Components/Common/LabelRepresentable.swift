//
//  LabelRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

/// Wrapper for UILabel
struct AttributedLabelRepresentable: UIViewRepresentable {
    var attributedText: NSAttributedString
    var width: CGFloat
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    
    func makeUIView(context: Context) -> UILabel {
        let view = UILabel()
        view.preferredMaxLayoutWidth = width
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 0
        view.lineBreakMode = .byWordWrapping
        view.font = font
        view.attributedText = attributedText
        return view
    }

    func updateUIView(_ view: UILabel, context: Context) {
        if view.attributedText != attributedText {
            view.attributedText = attributedText
        }
        if view.preferredMaxLayoutWidth != width {
            view.preferredMaxLayoutWidth = width
        }
        if view.font != font {
            view.font = font
        }
    }
}

struct LabelRepresentablePreview: PreviewProvider {
    static var previews: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    ForEach(Range(1...3)) { _ in
                        AttributedLabelRepresentable(
                            attributedText:
                                """
                                Life is good when you have [[wikilinks]]. They allow you to [[link to other pages by name]].
                                """.renderingWikilinks(url: { text in text }),
                            width: geometry.size.width
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
