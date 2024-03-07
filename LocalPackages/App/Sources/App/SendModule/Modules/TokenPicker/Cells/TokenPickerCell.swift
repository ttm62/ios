import UIKit
import TKUIKit

class TokenPickerCell: TKCollectionViewContainerCell<TokenPickerCellContentView> {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .Background.content
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class TokenPickerCellContentView: UIView, ConfigurableView, TKCollectionViewCellContentView, ReusableView {
  var padding: UIEdgeInsets { .init(top: 16, left: 16, bottom: 16, right: 16) }
  
  let iconView = TKListItemIconImageView()
  let contentView = TKListItemContentView()
  
  lazy var layout = TKListItemLayout(iconView: iconView, contentView: contentView, valueView: nil)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layout.layouSubviews(bounds: bounds)
  }
  
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return layout.calculateSize(targetSize: size)
  }
  
  struct Model {
    let iconModel: TKListItemIconImageView.Model
    let contentModel: TKListItemContentView.Model
    
    init(image: TKListItemIconImageView.Model.Image,
         backgroundColor: UIColor,
         tokenName: String,
         balance: String) {
      iconModel = TKListItemIconImageView.Model(
        image: image,
        tintColor: .clear,
        backgroundColor: .clear,
        size: CGSize(width: 44, height: 44)
      )
      
      let leftContentStackViewModel = TKListItemContentStackView.Model(
        titleSubtitleModel: TKListItemTitleSubtitleView.Model(
          title: tokenName.withTextStyle(
            .label1,
            color: .Text.primary,
            alignment: .left,
            lineBreakMode: .byTruncatingTail
          ),
          subtitle: balance.withTextStyle(
            .body2,
            color: .Text.secondary,
            alignment: .left,
            lineBreakMode: .byTruncatingTail
          )
        ),
        description: nil
      )
      
      contentModel = TKListItemContentView.Model(
        leftContentStackViewModel: leftContentStackViewModel,
        rightContentStackViewModel: nil
      )
    }
  }
  
  func configure(model: Model) {
    iconView.configure(model: model.iconModel)
    contentView.configure(model: model.contentModel)
  }
}

private extension TokenPickerCellContentView {
  func setup() {
    addSubview(iconView)
    addSubview(contentView)
  }
}
