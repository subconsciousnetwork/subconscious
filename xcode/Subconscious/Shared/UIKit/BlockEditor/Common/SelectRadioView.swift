//
//  SelectRadioView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/29/24.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class SelectRadioView: UIView {
        let size: CGFloat = 20
        let borderWidth: CGFloat = 2
        let frameSize: CGFloat = AppTheme.lineHeight

        override init(frame: CGRect) {
            super.init(frame: frame)

            self
                .anchorWidth(constant: size)
                .anchorHeight(constant: size)
                .contentHugging(for: .vertical)
                .contentHugging(for: .horizontal)
                .contentCompressionResistance(for: .vertical)
                .contentCompressionResistance(for: .horizontal)

            layer.cornerRadius = size / 2
            layer.borderWidth = 2
            settingSelected(false)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @discardableResult
        func settingSelected(_ isSelected: Bool) -> Self {
            if isSelected {
                layer.borderColor = UIColor(Color.accentColor).cgColor
                layer.backgroundColor = UIColor(Color.accentColor).cgColor
            } else {
                layer.borderColor = UIColor(Color.tertiaryIcon).cgColor
                layer.backgroundColor = UIColor.clear.cgColor
            }
            return self
        }
    }
}


struct BlockEditorSelectRadioView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UIViewPreviewRepresentable {
                UIStackView().vStack()
                    .addingArrangedSubview(
                        BlockEditor.SelectRadioView()
                            .settingSelected(true)
                    )
                    .addingArrangedSubview(
                        BlockEditor.SelectRadioView()
                            .settingSelected(false)
                    )
                    .addingArrangedSubview(
                        BlockEditor.SelectRadioView()
                    )
            }
        }
    }
}
