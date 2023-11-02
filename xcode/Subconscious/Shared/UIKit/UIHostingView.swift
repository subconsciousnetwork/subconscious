//
//  UIHostingView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/2/23.
//

import Foundation
import SwiftUI
import UIKit

// See here for another approach https://github.com/SwiftUIX/SwiftUIX/blob/master/Sources/Intermodular/Helpers/UIKit/UIHostingView.swift

// Get a view for a UIHostingController
// Assigns the UIHostingController to a parent controller
class UIHostingView<Content: View>: UIView {
    /// A reference to the hosting controller for this UIHostingView.
    /// We use this to remove hostingController from the parent controller
    /// on deinit.
    private var hostingController: UIHostingController<Content>
    
    init(
        frame: CGRect = .zero,
        parent: UIViewController?,
        hostingController: UIHostingController<Content>
    ) {
        self.hostingController = hostingController
        super.init(frame: frame)
        
        // Add hosting controller to parent controller
        if let parent = parent {
            parent.addChild(hostingController)
        }
        
        // Add hosting controler view to this view
        self.addSubview(hostingController.view)
        
        // Set hosting controller view constraints to match this view's
        // constraints.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            hostingController.view.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),
            hostingController.view.topAnchor.constraint(
                equalTo: self.topAnchor
            ),
            hostingController.view.bottomAnchor.constraint(
                equalTo: self.bottomAnchor
            )
        ])

        // Notify hosting controller it moved to parent
        // See https://developer.apple.com/documentation/uikit/view_controllers/creating_a_custom_container_view_controller
        hostingController.didMove(toParent: parent)
    }
    
    convenience init(
        frame: CGRect = .zero,
        parent: UIViewController?,
        view: Content
    ) {
        self.init(
            parent: parent,
            hostingController: UIHostingController(rootView: view)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        guard hostingController.parent != nil else {
            return
        }
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
    }
}

struct UIHostingView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            UIHostingView(
                parent: nil,
                view: Text("Hello from SwiftUI")
            )
        }
    }
}
