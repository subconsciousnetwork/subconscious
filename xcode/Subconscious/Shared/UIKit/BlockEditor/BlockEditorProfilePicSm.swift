//
//  BlockEditorProfilePicSm.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/5/23.
//

import UIKit

extension BlockEditor {
    class ProfilePicSmView: UIView, UIViewRenderableProtocol {
        private var size: CGFloat = 22
        private var imageView = UIImageView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = false
            imageView.clipsToBounds = true
            
            addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: size),
                imageView.heightAnchor.constraint(equalToConstant: size),
                widthAnchor.constraint(equalToConstant: size),
                heightAnchor.constraint(equalToConstant: size)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Apply the circle crop.
            // It's important to run this in `layoutSubviews`, since by this
            // lifecycle hook the view frame has a height assigned by
            // autolayout.
            imageView.layer.cornerRadius = frame.height / 2
            imageView.backgroundColor = UIColor.secondarySystemFill
        }
        
        func render(_ state: ProfilePicVariant?) {
            // TODO: implement generative profile pics for UIKit code
        }
    }
}
