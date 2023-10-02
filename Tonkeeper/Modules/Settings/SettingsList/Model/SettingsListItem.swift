//
//  SettingsListItem.swift
//  Tonkeeper
//
//  Created by Grigory on 2.10.23..
//

import UIKit

struct SettingsListItem {
  let title: String
  let option: SettingsListItemOption
}

enum SettingsListItemOption {
  case plain(SettingsListItemPlainOption)
  case switchOption(SettingsListItemSwitchOption)
}

struct SettingsListItemPlainOption {
  enum Accessory {
    struct Icon {
      let image: UIImage?
      let tintColor: UIColor
    }
    case value(String)
    case icon(Icon)
    case chevron
  }
  
  let accessory: Accessory
  let handler: () -> Void
}

struct SettingsListItemSwitchOption {
  let isOn: Bool
  let handler: () -> Void
}
