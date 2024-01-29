//
//  FluentUIView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/26/24.
//

import Foundation
import UIKit
import os

private let logger = Logger(
    subsystem: Config.default.rdns,
    category: "FluentObject"
)

private let SUPERVIEW_CONSTRAINT_WARNING =
    """
    Can't activate constraints. View has no superview.
        Tip: Add this view to a superview before creating constraints related to superview.
    """

protocol FluentObject: AnyObject {}

/// Modify a reference type using fluent method-chaining API style
extension FluentObject {
    /// Fluently mutate a reference-type object
    /// Performs `modify` closure, and then returns self for chaining.
    /// - Returns: Self
    @discardableResult
    func modifier(_ modify: (Self) -> Void) -> Self {
        modify(self)
        return self
    }

    /// Fluently set a property of a reference-type object
    /// Sets a value by key path and then returns self for chaining.
    /// - Returns: Self
    @discardableResult
    func setting<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, T>,
        value: T
    ) -> Self {
        self[keyPath: keyPath] = value
        return self
    }
}

extension UIView: FluentObject {
    /// Fluently add a subview, using a closure for additional modification of
    /// that subview, returning parent view after.
    /// - Returns: Self
    @discardableResult
    func addingSubview<Subview: UIView>(
        _ subview: Subview
    ) -> Self {
        self.addSubview(subview)
        return self
    }

    /// Fluently add a subview, using a closure for additional modification of
    /// that subview, returning parent view after.
    /// - Returns: Self
    @discardableResult
    func addingSubview<Subview: UIView>(
        _ subview: Subview,
        modify: (Subview) -> Void
    ) -> Self {
        self.addSubview(subview)
        modify(subview)
        return self
    }

    /// Ready a view for autolayout by setting
    /// `translatesAutoresizingMaskIntoConstraints` to `false`.
    @discardableResult
    func autolayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    /// Set content hugging priority
    /// - Returns: Self
    @discardableResult
    func contentHugging(
        _ priority: UILayoutPriority = .defaultHigh,
        for axis: NSLayoutConstraint.Axis
    ) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(
            priority,
            for: axis
        )
        return self
    }

    /// Set compression resistence
    /// - Returns: Self
    @discardableResult
    func contentCompressionResistance(
        _ priority: UILayoutPriority = .defaultHigh,
        for axis: NSLayoutConstraint.Axis
    ) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        setContentCompressionResistancePriority(
            priority,
            for: axis
        )
        return self
    }

    /// Anchor top edge to superview
    /// - Returns: Self
    @discardableResult
    func anchorTop(constant: CGFloat = 0) -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(
            equalTo: superview.topAnchor,
            constant: constant
        ).isActive = true
        return self
    }

    /// Anchor bottom edge to superview
    /// - Returns: Self
    @discardableResult
    func anchorBottom(constant: CGFloat = 0) -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        bottomAnchor.constraint(
            equalTo: superview.bottomAnchor,
            constant: -constant
        ).isActive = true
        return self
    }

    /// Anchor leading edge to superview
    /// - Returns: Self
    @discardableResult
    func anchorLeading(constant: CGFloat = 0) -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(
            equalTo: superview.leadingAnchor,
            constant: constant
        ).isActive = true
        return self
    }

    /// Anchor trailing edge to superview
    /// - Returns: Self
    @discardableResult
    func anchorTrailing(constant: CGFloat = 0) -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        trailingAnchor.constraint(
            equalTo: superview.trailingAnchor,
            constant: constant
        ).isActive = true
        return self
    }

    /// Anchor all edges to superview
    /// - Returns: Self
    @discardableResult
    func anchorEdges(edges: UIEdgeInsets = .zero) -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(
                equalTo: superview.topAnchor,
                constant: edges.top
            ),
            leadingAnchor.constraint(
                equalTo: superview.leadingAnchor,
                constant: edges.left
            ),
            bottomAnchor.constraint(
                equalTo: superview.bottomAnchor,
                constant: -edges.bottom
            ),
            trailingAnchor.constraint(
                equalTo: superview.trailingAnchor,
                constant: -edges.right
            )
        ])

        return self
    }

    /// Anchor all edges to superview
    /// - Returns: Self
    @discardableResult
    func anchorWidth(constant: CGFloat = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(
            equalToConstant: constant
        ).isActive = true
        return self
    }

    /// Anchor height to superview
    /// - Returns: Self
    @discardableResult
    func anchorHeight(constant: CGFloat = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(
            equalToConstant: constant
        ).isActive = true
        return self
    }

    /// Anchor center X to superview
    /// - Returns: Self
    @discardableResult
    func anchorCenterX() -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(
            equalTo: superview.centerXAnchor
        ).isActive = true
        return self
    }

    /// Anchor center Y to superview
    /// - Returns: Self
    @discardableResult
    func anchorCenterY() -> Self {
        guard let superview = superview else {
            logger.warning("\(SUPERVIEW_CONSTRAINT_WARNING)")
            return self
        }
        translatesAutoresizingMaskIntoConstraints = false
        self.centerYAnchor.constraint(
            equalTo: superview.centerYAnchor
        ).isActive = true
        return self
    }

    /// Approximate a CSS style "block" layout by anchoring all edges to
    /// superview, setting content hugging high and compression
    /// resistence high.
    /// - Returns: Self
    @discardableResult
    func layoutBlock(edges: UIEdgeInsets = .zero) -> Self {
        self
            .anchorEdges(edges: edges)
            .contentHugging(.defaultHigh, for: .vertical)
            .contentCompressionResistance(.defaultHigh, for: .vertical)
    }
}

extension UIStackView {
    /// Fluently add an arranged subview.
    /// - Returns: Self
    @discardableResult
    func addingArrangedSubview(_ view: UIView) -> Self {
        addArrangedSubview(view)
        return self
    }
}
