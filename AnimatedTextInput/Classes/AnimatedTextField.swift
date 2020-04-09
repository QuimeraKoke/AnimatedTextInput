import UIKit

final internal class AnimatedTextField: UITextField {

    enum TextFieldType {
        case text
        case password
        case numeric
        case selection
    }

    fileprivate let defaultPadding: CGFloat = -16

    var rightViewPadding: CGFloat
    weak public var textInputDelegate: TextInputDelegate?

    public var textAttributes: [NSAttributedString.Key: Any]?
    public var contentInset: UIEdgeInsets = .zero

    fileprivate var disclosureButtonAction: (() -> Void)?

    override public init(frame: CGRect) {
        self.rightViewPadding = defaultPadding

        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.rightViewPadding = defaultPadding

        super.init(coder: aDecoder)

        setup()
    }

    fileprivate func setup() {
        delegate = self
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @discardableResult override public func becomeFirstResponder() -> Bool {
        if let alignment = (textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle)?.alignment {
            textAlignment = alignment
        }
        return super.becomeFirstResponder()
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.rightViewRect(forBounds: bounds).offsetBy(dx: rightViewPadding, dy: 0)
    }

//    override public func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
//        return super.clearButtonRect(forBounds: bounds).offsetBy(dx: clearButtonPadding, dy: 0)
//    }
    
    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        var width = bounds.width
        if clearButtonMode == .always || clearButtonMode == .unlessEditing {
            width = bounds.width - clearButtonRect(forBounds: bounds).width * 2
        }
        
        return CGRect(x: bounds.origin.x + contentInset.left,
                      y: bounds.origin.y + contentInset.top,
                      width: width - contentInset.left - contentInset.right,
                      height: bounds.height - contentInset.top - contentInset.bottom)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        var width = bounds.width
        if clearButtonMode != .never {
            width = bounds.width - clearButtonRect(forBounds: bounds).width * 2
        } else if let _ = rightView {
            width = bounds.width - rightViewRect(forBounds: bounds).width * 2
        }
        return CGRect(x: bounds.origin.x + contentInset.left,
                      y: bounds.origin.y + contentInset.top,
                      width: width - contentInset.left - contentInset.right,
                      height: bounds.height - contentInset.top - contentInset.bottom)
    }

    func add(disclosureButton button: UIButton, action: @escaping (() -> Void)) {
        let selector = #selector(disclosureButtonPressed)
        if disclosureButtonAction != nil, let previousButton = rightView as? UIButton {
            previousButton.removeTarget(self, action: selector, for: .touchUpInside)
        }
        disclosureButtonAction = action
        button.addTarget(self, action: selector, for: .touchUpInside)
        rightView = button
    }

    @objc fileprivate func disclosureButtonPressed() {
        disclosureButtonAction?()
    }

    @objc fileprivate func textFieldDidChange() {
        textInputDelegate?.textInputDidChange(self)
    }
}

extension AnimatedTextField: TextInput {

    public func configureInputView(newInputView: UIView) {
        inputView = newInputView
    }

    public func changeReturnKeyType(with newReturnKeyType: UIReturnKeyType) {
        returnKeyType = newReturnKeyType
    }
    
    public func currentPosition(from: UITextPosition, offset: Int) -> UITextPosition? {
        return position(from: from, offset: offset)
    }
    
    public func changeClearButtonMode(with newClearButtonMode: UITextField.ViewMode) {
        clearButtonMode = newClearButtonMode
    }

    @available(iOS 8.0, *)
    var view: UIView { return self }
    var currentText: String? {
        get { return text }
        set { self.text = newValue }
    }
    
    var autocorrection: UITextAutocorrectionType {
        get { return self.autocorrectionType }
        set { self.autocorrectionType = newValue }
    }

    @available(iOS 10.0, *)
    var currentTextContentType: UITextContentType {
        get { return self.textContentType }
        set { self.textContentType = newValue }
    }

//    var textAttributes: [String: AnyObject] {
//        get { return typingAttributes as [String : AnyObject]? ?? [:] }
//        set { self.typingAttributes = textAttributes }
        
    var currentSelectedTextRange: UITextRange? {
        get { return self.selectedTextRange }
        set { self.selectedTextRange = newValue }
    }

    var currentBeginningOfDocument: UITextPosition? {
        get { return self.beginningOfDocument }
    }
    
    var currentKeyboardAppearance: UIKeyboardAppearance {
        get { return self.keyboardAppearance }
        set { self.keyboardAppearance = newValue}
    }
}

extension AnimatedTextField: TextInputError {

    func configureErrorState(with message: String?) {
        placeholder = message
    }

    func removeErrorHintMessage() {
        placeholder = nil
    }
}

extension AnimatedTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textInputDelegate?.textInputDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textInputDelegate?.textInputDidEndEditing(self)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textInputDelegate?.textInput(self, shouldChangeCharactersInRange: range, replacementString: string) ?? true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldBeginEditing(self) ?? true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldEndEditing(self) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldReturn(self) ?? true
    }
}
