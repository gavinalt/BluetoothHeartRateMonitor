//
//  LogViewController.swift
//  Bluetooth
//
//  Created by Gavin Li on 6/29/20.
//  Copyright © 2020 Gavin Li. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {
  var kvoToken: NSKeyValueObservation?
  var scrollView: UIScrollView = UIScrollView.init(frame: .zero)
  var sysLog: UILabel = UILabel.init(frame: .zero)

  override func viewDidLoad() {
    super.viewDidLoad()
    if let mainNavController = self.tabBarController?.viewControllers?[0] as? UINavigationController,
      let mainVC = mainNavController.viewControllers[0] as? MainViewController {
      observe(mainVC: mainVC)
    }

    setupView()
  }

  private func setupView() {
    scrollView.fill(in: view)
    sysLog.fillIgnoreMargin(in: scrollView)
    NSLayoutConstraint.activate([
      sysLog.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor)
    ])

    sysLog.numberOfLines = 0
    sysLog.lineBreakMode = .byWordWrapping
    sysLog.font = UIFont.init(name: "Menlo", size: 12)
  }

  func observe(mainVC: MainViewController) {
    kvoToken = mainVC.observe(\.cbLog, options: [.initial, .new]) { [weak self] (viewController, change) in
      guard let newLog = change.newValue else { return }
      self?.sysLog.text = newLog
    }
  }

  deinit {
    kvoToken?.invalidate()
  }
}
