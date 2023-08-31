//
//  UIRenderableViewProtocol.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

/// A UIView that implements a render method
protocol UIRenderableViewProtocol: UIView {
    associatedtype Model
    
    func render(_ state: Model)
}

/// View that has an ID and implements a render method
protocol UIComponentViewProtocol: UIRenderableViewProtocol, Identifiable {
    var id: UUID { get }
}
