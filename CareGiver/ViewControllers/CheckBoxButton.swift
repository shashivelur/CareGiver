import UIKit
class CheckboxButton: UIButton {
    private let checkedImage = UIImage(systemName: "checkmark.square.fill")
    private let uncheckedImage = UIImage(systemName: "square")

    var isChecked: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        updateAppearance()
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 24).isActive = true
        heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    @objc private func toggle() {
        isChecked.toggle()
        sendActions(for: .valueChanged)
    }

    private func updateAppearance() {
        let image = isChecked ? checkedImage : uncheckedImage
        setImage(image, for: .normal)
        tintColor = isChecked ? .systemGreen : .lightGray
        
        // Add green background when checked
        if isChecked {
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            layer.cornerRadius = 4
        } else {
            backgroundColor = .clear
        }
    }
}

