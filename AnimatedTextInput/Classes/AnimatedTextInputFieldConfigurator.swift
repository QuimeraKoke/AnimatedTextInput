import UIKit

public struct AnimatedTextInputFieldConfigurator {
    
    public enum AnimatedTextInputType {
        case standard
        case password
        case numeric
        case phone
        case selection
        case customSelection(isRightViewEnabled: Bool, rightViewImage: UIImage?)
        case multiline
        case generic(textInput: TextInput)
    }
    
    static func configure(with type: AnimatedTextInputType) -> TextInput {
        switch type {
        case .standard:
            return AnimatedTextInputTextConfigurator.generate()
        case .password:
            return AnimatedTextInputPasswordConfigurator.generate()
        case .numeric:
            return AnimatedTextInputNumericConfigurator.generate()
        case .phone:
            return AnimatedTextInputPhoneConfigurator.generate()
        case .selection:
            return AnimatedTextInputSelectionConfigurator.generate()
        case .multiline:
            return AnimatedTextInputMultilineConfigurator.generate()
        case .generic(let textInput):
            return textInput
        case .customSelection(let isRightViewEnabled, let rightViewImage):
            return AnimatedTextInputCustomSelectionConfigurator.generate(isRightViewEnabled: isRightViewEnabled, rightViewImage: rightViewImage)
        }
    }
}

fileprivate struct AnimatedTextInputTextConfigurator {
    
    static func generate() -> TextInput {
        let textField = AnimatedTextField()
        textField.clearButtonMode = .whileEditing
        return textField
    }
}

fileprivate struct AnimatedTextInputEmailConfigurator {
    
    static func generate() -> TextInput {
        let textField = AnimatedTextField()
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }
}

fileprivate struct AnimatedTextInputPasswordConfigurator {
    
    static func generate(toggleable: Bool) -> TextInput {
        let textField = AnimatedTextField()
        textField.rightViewMode = .whileEditing
        textField.isSecureTextEntry = true
        let disclosureButton = UIButton(type: .custom)
        disclosureButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20))
        let bundle = Bundle(path: Bundle(for: AnimatedTextInput.self).path(forResource: "AnimatedTextInput", ofType: "bundle")!)
        let normalImage = UIImage(named: "cm_icon_input_eye_normal", in: bundle, compatibleWith: nil)
        let selectedImage = UIImage(named: "cm_icon_input_eye_selected", in: bundle, compatibleWith: nil)
        disclosureButton.setImage(normalImage, for: UIControlState())
        disclosureButton.setImage(selectedImage, for: .selected)
        textField.add(disclosureButton: disclosureButton) {
            disclosureButton.isSelected = !disclosureButton.isSelected
            textField.resignFirstResponder()
            textField.isSecureTextEntry = !textField.isSecureTextEntry
            textField.becomeFirstResponder()
        }
        return textField
    }
}

fileprivate struct AnimatedTextInputNumericConfigurator {
    
    static func generate() -> TextInput {
        let textField = AnimatedTextField()
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .decimalPad
        return textField
    }
}

fileprivate struct AnimatedTextInputPhoneConfigurator {
    
    static func generate() -> TextInput {
        let textField = AnimatedTextField()
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .phonePad
        textField.autocorrectionType = .no
        return textField
    }
}

fileprivate struct AnimatedTextInputSelectionConfigurator {
    
    static func generate() -> TextInput {
        let textField = AnimatedTextField()
        let arrowImageView = UIImageView(image: UIImage(named: "disclosure-indicator"))
        textField.rightView = arrowImageView
        textField.rightViewMode = .always
        textField.isUserInteractionEnabled = false
        return textField
    }
}

fileprivate struct AnimatedTextInputCustomSelectionConfigurator {
    
    static func generate(isRightViewEnabled: Bool = true, rightViewImage: UIImage? = nil) -> TextInput {
        let textField = AnimatedTextField()
        if isRightViewEnabled && rightViewImage != nil {
            let arrowImageView = UIImageView(image: rightViewImage)
            textField.rightView = arrowImageView
            textField.rightViewMode = .always
        }
        textField.isUserInteractionEnabled = false
        return textField
    }
}


fileprivate struct AnimatedTextInputMultilineConfigurator {
    
    static func generate() -> TextInput {
        let textView = AnimatedTextView()
        textView.textContainerInset = UIEdgeInsets.zero
        textView.backgroundColor = UIColor.clear
        textView.isScrollEnabled = false
        return textView
    }
}
