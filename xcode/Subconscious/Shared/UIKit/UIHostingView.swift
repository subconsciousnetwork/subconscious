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

/// Get a view for a UIHostingController.
///
/// View holds a reference to UIHostingController. Controller can be added to
/// a parent controller during initialization, or after using
/// `.moveToParentControllerIfNeeded()`. Hosting controller will be removed
/// from parent controller automatically when this view is deinitialized.
///
/// This is particularly useful when embedding a SwiftUI view inside something
/// that must be a view, such as UICollectionViewCell.
class UIHostingView<Content: View>: UIView {
    /// A reference to the hosting controller for this UIHostingView.
    /// We use this to remove hostingController from the parent controller
    /// on deinit.
    ///
    /// Note that we allow for an optional view in the hosting controller.
    /// This lets us set a SwiftUI view after initialization.
    /// Useful for cases like
    /// `.collectionView.dequeueReusableCell(withReuseIdentifier:for:)`,
    /// where the cell must be initialized with zero arguments, and then
    /// configured after initialization.
    private var hostingController = UIHostingController<Content?>(
        rootView: nil
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addingSubview(hostingController.view) { hostingControllerView in
            hostingControllerView
                .setting(\.backgroundColor, value: .clear)
                .layoutBlock()
        }

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
