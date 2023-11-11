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
    private var hostingController = UIHostingController<Content?>(
        rootView: nil
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Add hosting controler view to this view
        self.addSubview(hostingController.view)
        
        hostingController.view
            .translatesAutoresizingMaskIntoConstraints = false
        
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
    }

    convenience init(
        frame: CGRect = .zero,
        parentController: UIViewController,
        rootView: Content
    ) {
        self.init(frame: frame)
        self.update(parentController: parentController, rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Update the SwiftUI View being managed by the hosting controller.
    /// This method is idempotent when called repeatedly with the
    /// same controller.
    func moveToParentControllerIfNeeded(
        _ parentController: UIViewController
    ) {
        guard hostingController.parent != parentController else {
            return
        }
        
        parentController.addChild(hostingController)
        
        // Notify hosting controller it moved to parent
        // See https://developer.apple.com/documentation/uikit/view_controllers/creating_a_custom_container_view_controller
        hostingController.didMove(toParent: parentController)
    }

    /// Update the SwiftUI View being managed by the hosting controller.
    @MainActor
    func update(rootView: Content?) {
        // Set root SwiftUI view on hosting controller
        self.hostingController.rootView = rootView
        // Invalidate intrinsic content size so that UIKit View will know
        // what size it should be with the new SwiftUI view.
        self.hostingController.view.invalidateIntrinsicContentSize()
    }

    @MainActor
    func update(
        parentController: UIViewController,
        rootView: Content?
    ) {
        moveToParentControllerIfNeeded(parentController)
        update(rootView: rootView)
    }

    deinit {
        guard hostingController.parent != nil else {
            return
        }
        hostingController.willMove(toParent: nil)
        hostingController.removeFromParent()
    }
}

struct UIHostingView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = UIHostingView<Text>()
            view.update(rootView: Text("Hello from SwiftUI"))
            return view
        }
    }
}
