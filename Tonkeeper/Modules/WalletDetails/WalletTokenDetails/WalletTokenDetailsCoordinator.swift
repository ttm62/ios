//
//  WalletTokenDetailsCoordinator.swift
//  Tonkeeper
//
//  Created by Grigory on 13.7.23..
//

import UIKit
import WalletCore

final class WalletTokenDetailsCoordinator: Coordinator<NavigationRouter> {
  
  private let walletCoreAssembly: WalletCoreAssembly
  
  let token: Token
  
  init(token: Token,
       walletCoreAssembly: WalletCoreAssembly,
       router: NavigationRouter) {
    self.token = token
    self.walletCoreAssembly = walletCoreAssembly
    super.init(router: router)
  }
  
  override func start() {
    openTokenDetails()
  }
}

private extension WalletTokenDetailsCoordinator {
  func openTokenDetails() {
    let tokenDetailsController: TokenDetailsController
    switch token {
    case .token(let tokenInfo):
      tokenDetailsController = walletCoreAssembly.tokenDetailsTokenController(tokenInfo: tokenInfo)
    case .ton:
      tokenDetailsController = walletCoreAssembly.tokenDetailsTonController()
    }
    
    let module = TokenDetailsAssembly.module(output: self,
                                             tokenDetailsController: tokenDetailsController,
                                             imageLoader: NukeImageLoader())
    module.view.setupBackButton()
    initialPresentable = module.view
  }
}

// MARK: - TokenDetailsModuleOutput

extension WalletTokenDetailsCoordinator: TokenDetailsModuleOutput {
  
}
