//
//  UIKit+Utility.swift
//  Bluetooth
//
//  Created by Gavin Li on 6/29/20.
//  Copyright © 2020 Gavin Li. All rights reserved.
//
import UIKit

extension UIView {
  func fillIgnoreMargin(in view: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(self)
    let constraints = [
      topAnchor.constraint(equalTo: view.topAnchor),
      bottomAnchor.constraint(equalTo: view.bottomAnchor),
      leadingAnchor.constraint(equalTo: view.leadingAnchor),
      trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ]
    NSLayoutConstraint.activate(constraints)
  }

  func fill(in view: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(self)
    let guide: UILayoutGuide
    if #available(iOS 11.0, *) {
      guide = view.safeAreaLayoutGuide
    } else {
      guide = view.layoutMarginsGuide
    }
    let constraints = [
      topAnchor.constraint(equalTo: guide.topAnchor),
      bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      trailingAnchor.constraint(equalTo: guide.trailingAnchor)
    ]
    NSLayoutConstraint.activate(constraints)
  }

  func fill(in view: UIView, leadingMargin leading: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(self)
    let guide: UILayoutGuide
    if #available(iOS 11.0, *) {
      guide = view.safeAreaLayoutGuide
    } else {
      guide = view.layoutMarginsGuide
    }
    let constraints = [
      topAnchor.constraint(equalTo: guide.topAnchor),
      bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: leading),
      trailingAnchor.constraint(equalTo: guide.trailingAnchor)
    ]
    NSLayoutConstraint.activate(constraints)
  }
}
