//
//  UIViewHelpers.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import UIKit

extension UIView {
    func subviews<T>(ofType type: T.Type) -> [T] {
        subviews.compactMap({ view in
            view as? T
        })
    }
}

extension UIView {
    func setFirstResponder(_ wantsFirstResponder: Bool) {
        if !isFirstResponder && wantsFirstResponder {
            becomeFirstResponder()
        } else if isFirstResponder && !wantsFirstResponder {
            resignFirstResponder()
        }
    }
    
    func setFirstResponderAsync(_ wantsFirstResponder: Bool) {
        DispatchQueue.main.async {
            if !self.isFirstResponder && wantsFirstResponder {
                self.becomeFirstResponder()
            } else if self.isFirstResponder && !wantsFirstResponder {
                self.resignFirstResponder()
            }
        }
    }
}
