import UIKit

final internal class AnimatedTextView: UITextView {

    public var textAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            guard let attributes = textAttributes else { return }
            typingAttributes = Dictionary(uniqueKeysWithValues: attributes.lazy.map { ($0.key, $0.value) })
        }
    }

    public override var font: UIFont? {
        didSet {
            var attributes = typingAttributes
            attributes[NSAttributedString.Key.font] = font
            textAttributes = Dictionary(uniqueKeysWithValues: attributes.lazy.map { ($0.key, $0.value)})
        }
    }

    public weak var textInputDelegate: TextInputDelegate?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    fileprivate func setup() {
        delegate = self
    }

    override func resignFirstResponder() -> Bool {
        return super.resignFirstResponder()
    }
}

extension AnimatedTextView: TextInput {
    public func configureInputView(newInputView: UIView) {
        inputView = newInputView
    }

    var view: UIView { return self }

    var currentText: String? {
        get { return text }
        set { self.text = newValue }
    }

    var textAttributes: [String: AnyObject] {
        get { return typingAttributes as [String : AnyObject] }
        set { self.typingAttributes = textAttributes }
    }

    public var currentBeginningOfDocument: UITextPosition? {
        return self.beginningOfDocument
    }
    
    public var currentKeyboardAppearance: UIKeyboardAppearance {
        get { return self.keyboardAppearance }
        set { self.keyboardAppearance = newValue}
    }

    public var autocorrection: UITextAutocorrectionType {
        get { return self.autocorrectionType }
        set { self.autocorrectionType = newValue }
    }

    @available(iOS 10.0, *)
    public var currentTextContentType: UITextContentType {
        get { return self.textContentType }
        set { self.textContentType = newValue }
    }

    public func changeReturnKeyType(with newReturnKeyType: UIReturnKeyType) {
        returnKeyType = newReturnKeyType
    }
    
    public func currentPosition(from: UITextPosition, offset: Int) -> UITextPosition? {
        return position(from: from, offset: offset)
    }
    
    public func changeClearButtonMode(with newClearButtonMode: UITextField.ViewMode) {}
    
}

extension AnimatedTextView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        textInputDelegate?.textInputDidBeginEditing(self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textInputDelegate?.textInputDidEndEditing(self)
    }

    func textViewDidChange(_ textView: UITextView) {
        textInputDelegate?.textInputDidChange(self)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return textInputDelegate?.textInputShouldReturn(self) ?? true
        }
        return textInputDelegate?.textInput(self, shouldChangeCharactersInRange: range, replacementString: text) ?? true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return textInputDelegate?.textInputShouldBeginEditing(self) ?? true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return textInputDelegate?.textInputShouldEndEditing(self) ?? true
    }
}
