//
//  BlockEditorTranscludeView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

extension BlockEditor {
    class TranscludeView: UIView, Identifiable {
        var id = UUID()
        private lazy var stackView = UIStackView(frame: .zero)
        private lazy var addressView = UILabel(frame: .zero)
        private lazy var excerptView = UILabel(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            addressView.translatesAutoresizingMaskIntoConstraints = false
            excerptView.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.addArrangedSubview(addressView)
            stackView.addArrangedSubview(excerptView)
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(
            _ stub: EntryStub
        ) {
            self.addressView.text = stub.address.description
            self.excerptView.text = stub.excerpt
        }
    }
}
