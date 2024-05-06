import Foundation
import UIKit
import TKUIKit
import SignerCore

protocol KeyDetailsViewModel: AnyObject {
  var titleUpdate: ((String) -> Void)? { get set }
  var itemsListUpdate: ((NSDiffableDataSourceSnapshot<KeyDetailsSection, AnyHashable>) -> Void)? { get set }
  var didSelectDelete: (() -> Void)? { get set }
  var didOpenUrl: ((URL) -> Void)? { get set }
  var didCopied: (() -> Void)? { get set }
  
  func viewDidLoad()
  func didConfirmDelete()
  func generateQRCode(width: CGFloat)
}

protocol KeyDetailsModuleOutput: AnyObject {
  var didTapEdit: (() -> Void)? { get set }
  var didTapOpenRecoveryPhrase: (() -> Void)? { get set }
  var didDeleteKey: (() -> Void)? { get set }
}

final class KeyDetailsViewModelImplementation: KeyDetailsViewModel, KeyDetailsModuleOutput {

  // MARK: - KeyDetailsModuleOutput
  
  var didTapEdit: (() -> Void)?
  var didTapOpenRecoveryPhrase: (() -> Void)?
  var didDeleteKey: (() -> Void)?
  var didOpenUrl: ((URL) -> Void)?
  var didCopied: (() -> Void)?
  
  // MARK: - KeyDetailsViewModel
  
  var titleUpdate: ((String) -> Void)?
  var itemsListUpdate: ((NSDiffableDataSourceSnapshot<KeyDetailsSection, AnyHashable>) -> Void)?
  var didSelectDelete: (() -> Void)?
  
  func viewDidLoad() {
    keyDetailsController.didUpdateWalletKey = { [weak self] walletKey in
      guard let self else { return }
      self.titleUpdate?(walletKey.name)
      updateList()
    }
    keyDetailsController.start()
  }
  
  func didConfirmDelete() {
    do {
      try keyDetailsController.deleteKey()
      didDeleteKey?()
    } catch {}
  }
  
  func generateQRCode(width: CGFloat) {
    Task {
      guard let url = keyDetailsController.appLinkDeeplinkUrl() else { return }
      let image = await qrCodeGenerator.generate(string: url.absoluteString, size: CGSize(width: width, height: width))
      await MainActor.run {
        self.qrCodeImage = image
        updateList()
      }
    }
  }
  
  // MARK: - State
  
  private var qrCodeImage: UIImage?
  
  // MARK: - Dependencies
  
  private let keyDetailsController: WalletKeyDetailsController
  private let qrCodeGenerator = QRCodeGeneratorImplementation()
  
  // MARK: - Init
  
  init(keyDetailsController: WalletKeyDetailsController) {
    self.keyDetailsController = keyDetailsController
  }
}

private extension KeyDetailsViewModelImplementation {
  
  func updateList() {
    var snapshot = NSDiffableDataSourceSnapshot<KeyDetailsSection, AnyHashable>()
    let sections = createSections()
    snapshot.appendSections(sections)
    for section in sections {
      snapshot.appendItems(section.items, toSection: section)
    }
    
    itemsListUpdate?(snapshot)
  }
  
  func createSections() -> [KeyDetailsSection] {
    return [
      createQRCodeSection(),
      createDeviceLinkSection(),
      createWebLinkSection(),
      createActionsSection(),
      createDeleteSection()
    ]
  }
  
  func createQRCodeSection() -> KeyDetailsSection {
    KeyDetailsSection(
      type: .qrCode,
      items: [
        createListItem(id: .qrCodeDescriptionItemIdentifier,
                       title: "Export to another device",
                       subtitle: "Open Tonkeeper » Import Existing Wallet » Pair Tonsign",
                       image: nil,
                       tintColor: .clear,
                       action: { [weak self] in
                         self?.sameDeviceLinkAction()
        }),
        KeyDetailsQRCodeCell.Model(image: qrCodeImage)
      ]
    )
  }
  
  func createDeviceLinkSection() -> KeyDetailsSection {
    KeyDetailsSection(
      type: .deviceLink,
      items: [
        createListItem(id: .linkToDeviceItemIdentifier,
                       title: "Link to Tonkeeper on this device",
                       subtitle: "Tonkeeper must be installed",
                       image: .TKUIKit.Icons.Size16.chevronRight,
                       tintColor: .Icon.tertiary,
                       action: { [weak self] in
                         self?.sameDeviceLinkAction()
        })
      ]
    )
  }
  
  func createWebLinkSection() -> KeyDetailsSection {
    KeyDetailsSection(
      type: .webLink,
      items: [
        createListItem(id: .linkToWebItemIdentifier,
                       title: "Link to Tonkeeper Web",
                       subtitle: "wallet.tonkeeper.com",
                       image: .TKUIKit.Icons.Size16.chevronRight,
                       tintColor: .Icon.tertiary,
                       action: { [weak self] in
                         self?.webLinkAction()
        })
      ]
    )
  }
  
  func createActionsSection() -> KeyDetailsSection {
    KeyDetailsSection(
      type: .actions,
      items: [
        createListItem(id: .nameItemIdentifier,
                       title: "Name",
                       subtitle: keyDetailsController.walletKey.name,
                       image: .TKUIKit.Icons.Size28.pencil,
                       tintColor: .Accent.blue,
                       action: { [weak self] in
                         self?.didTapEdit?()
        }),
        createListItem(id: .hexItemIdentifier,
                       title: "Hex Address",
                       subtitle: keyDetailsController.walletKey.publicKeyShortHexString,
                       image: .TKUIKit.Icons.Size28.copy,
                       tintColor: .Accent.blue,
                       action: { [weak self] in
                         self?.didCopied?()
        }),
        createListItem(id: .recoveryPhraseItemIdentifier,
                       title: "Recovery Phrase",
                       image: .TKUIKit.Icons.Size28.key,
                       tintColor: .Accent.blue,
                       action: { [weak self] in
                         self?.didTapOpenRecoveryPhrase?()
        })
      ]
    )
  }
  
  func createDeleteSection() -> KeyDetailsSection {
    KeyDetailsSection(
      type: .delete,
      items: [
        createListItem(id: .deleteItemIdentifier,
                       title: "Delete Key",
                       image: .TKUIKit.Icons.Size28.trashBin,
                       tintColor: .Accent.blue,
                       action: { [weak self] in
                         self?.didSelectDelete?()
        })
      ]
    )
  }
  
  func createListItem(id: String, 
                      title: String,
                      subtitle: String? = nil,
                      image: UIImage?,
                      tintColor: UIColor,
                      action: @escaping () -> Void) -> TKUIListItemCell.Configuration {
    let accessoryConfiguration: TKUIListItemAccessoryView.Configuration
    if let image {
      accessoryConfiguration = .image(
        TKUIListItemImageAccessoryView.Configuration(
          image: image,
          tintColor: tintColor,
          padding: .zero
        )
      )
    } else {
      accessoryConfiguration = .none
    }
    
    return TKUIListItemCell.Configuration(
      id: id,
      listItemConfiguration: TKUIListItemView.Configuration(
        contentConfiguration: TKUIListItemContentView.Configuration(
          leftItemConfiguration: TKUIListItemContentLeftItem.Configuration(
            title: title.withTextStyle(
              .label1,
              color: .Text.primary,
              alignment: .left,
              lineBreakMode: .byTruncatingTail
            ),
            tagViewModel: nil,
            subtitle: nil,
            description: subtitle?.withTextStyle(.body2, color: .Text.secondary)
          ),
          rightItemConfiguration: nil
        ),
        accessoryConfiguration: accessoryConfiguration
      ),
      selectionClosure: {
        action()
      }
    )
  }
  
  private func sameDeviceLinkAction() {
    guard let url = keyDetailsController.appLinkDeeplinkUrl() else { return }
    didOpenUrl?(url)
  }
  
  private func webLinkAction() {
    guard let url = keyDetailsController.webLinkDeeplinkUrl() else { return }
    didOpenUrl?(url)
  }
}

private extension String {
  static let deleteItemIdentifier = "DeleteItemIdentifier"
  static let nameItemIdentifier = "NameItemIdentifier"
  static let hexItemIdentifier = "HexItemIdentifier"
  static let recoveryPhraseItemIdentifier = "RecoveryPhraseItemIdentifier"
  static let linkToWebItemIdentifier = "LinkToWebItemIdentifier"
  static let linkToDeviceItemIdentifier = "LinkToDeviceItemIdentifier"
  static let qrCodeDescriptionItemIdentifier = "QRCodeDescriptionItemIdentifier"
}