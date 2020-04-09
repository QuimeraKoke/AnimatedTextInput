import UIKit

@objc public protocol AnimatedTextInputDelegate: class {

    @objc optional func animatedTextInputDidBeginEditing(_ animatedTextInput: AnimatedTextInput)
    @objc optional func animatedTextInputDidEndEditing(_ animatedTextInput: AnimatedTextInput)
    @objc optional func animatedTextInputDidChange(_ animatedTextInput: AnimatedTextInput)
    @objc optional func animatedTextInput(_ animatedTextInput: AnimatedTextInput, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    @objc optional func animatedTextInputShouldBeginEditing(_ animatedTextInput: AnimatedTextInput) -> Bool
    @objc optional func animatedTextInputShouldEndEditing(_ animatedTextInput: AnimatedTextInput) -> Bool
    @objc optional func animatedTextInputShouldReturn(_ animatedTextInput: AnimatedTextInput) -> Bool
}

open class AnimatedTextInput: UIControl {

    public typealias AnimatedTextInputType = AnimatedTextInputFieldConfigurator.AnimatedTextInputType

    open var tapAction: (() -> Void)?
    open  weak var delegate: AnimatedTextInputDelegate?
    open fileprivate(set) var isActive = false

    open var type: AnimatedTextInputType = .multiline {
        didSet {
            configureType()
        }
    }
    
    open var autocorrection: UITextAutocorrectionType = .no {
        didSet {
            textInput.autocorrection = autocorrection
        }
    }

    @available(iOS 10.0, *)
    open var textContentType: UITextContentType {
        get { return textInput.currentTextContentType }
        set { textInput.currentTextContentType = newValue }
    }

    open var returnKeyType: UIReturnKeyType = .default {
        didSet {
            textInput.changeReturnKeyType(with: returnKeyType)
        }
    }

    open var keyboardAppearance: UIKeyboardAppearance {
        get { return textInput.currentKeyboardAppearance }
        set { textInput.currentKeyboardAppearance = newValue }
    }
    
    open var clearButtonMode: UITextField.ViewMode = .whileEditing {
        didSet {
            textInput.changeClearButtonMode(with: clearButtonMode)
        }
    }

    open var placeHolderText = "Test" {
        didSet {
            placeholderLayer.string = placeHolderText
            textInput.view.accessibilityLabel = placeHolderText
        }
    }
    
    // Some letters like 'g' or 'á' were not rendered properly, the frame need to be about 20% higher than the font size

    open var frameHeightCorrectionFactor : Double = 1.2 {
        didSet {
            layoutPlaceholderLayer()
        }

    }
    
    open var placeholderAlignment: CATextLayer.Alignment = .natural {
        didSet {
            placeholderLayer.alignmentMode = CATextLayerAlignmentMode(rawValue: String(describing: placeholderAlignment))
        }
    }

    open var style: AnimatedTextInputStyle = AnimatedTextInputStyleBlue() {
        didSet {
            configureStyle()
        }
    }

    open var text: String? {
        get {
            return textInput.currentText
        }
        set {
            (newValue != nil && !newValue!.isEmpty) ? configurePlaceholderAsInactiveHint() : configurePlaceholderAsDefault()
            textInput.currentText = newValue
        }
    }

    open var selectedTextRange: UITextRange? {
        get { return textInput.currentSelectedTextRange }
        set { textInput.currentSelectedTextRange = newValue }
    }

    open var beginningOfDocument: UITextPosition? {
        get { return textInput.currentBeginningOfDocument }
    }

    open var font: UIFont? {
        get { return textInput.font }
        set { textAttributes = [NSAttributedString.Key.font: newValue as Any] }
    }

    open var textColor: UIColor? {
        get { return textInput.textColor }
        set { textAttributes = [NSAttributedString.Key.foregroundColor: newValue as Any] }
    }

    open var lineSpacing: CGFloat? {
        get {
            guard let paragraph = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle else { return nil }
            return paragraph.lineSpacing
        }
        set {
            guard let spacing = newValue else { return }
            let paragraphStyle = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = spacing
            textAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        }
    }

    open var textAlignment: NSTextAlignment? {
        get {
            guard let paragraph = textInput.textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle else { return nil }
            return paragraph.alignment
        }
        set {
            guard let alignment = newValue else { return }
            let paragraphStyle = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            textAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        }
    }

    open var tailIndent: CGFloat? {
        get {
            guard let paragraph = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle else { return nil }
            return paragraph.tailIndent
        }
        set {
            guard let indent = newValue else { return }
            let paragraphStyle = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.tailIndent = indent
            textAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        }
    }

    open var headIndent: CGFloat? {
        get {
            guard let paragraph = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle else { return nil }
            return paragraph.headIndent
        }
        set {
            guard let indent = newValue else { return }
            let paragraphStyle = textAttributes?[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.headIndent = indent
            textAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        }
    }

    open var textAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            guard var textInputAttributes = textInput.textAttributes else {
                textInput.textAttributes = textAttributes
                return
            }
            guard textAttributes != nil else {
                textInput.textAttributes = nil
                return
            }
            textInput.textAttributes = textInputAttributes.merge(dict: textAttributes!)
        }
    }

    private var _inputAccessoryView: UIView?

    open override var inputAccessoryView: UIView? {
        set {
            _inputAccessoryView = newValue
        }

        get {
            return _inputAccessoryView
        }
    }

    open var contentInset: UIEdgeInsets? {
        didSet {
            guard let insets = contentInset else { return }
            textInput.contentInset = insets
        }
    }

    fileprivate let lineView = AnimatedLine()
    fileprivate let placeholderLayer = CATextLayer()
    fileprivate let counterLabel = UILabel()
    fileprivate let lineWidth: CGFloat = 1
    fileprivate let counterLabelRightMargin: CGFloat = 15
    fileprivate let counterLabelTopMargin: CGFloat = 5

    fileprivate var isPlaceholderAsHint = false
    fileprivate var hasCounterLabel = false
    fileprivate var textInput: TextInput!
    fileprivate var placeholderErrorText = "Error message"
    fileprivate var lineToBottomConstraint: NSLayoutConstraint!

    fileprivate var placeholderPosition: CGPoint {
        let hintPosition = CGPoint(x: 3, y: style.yHintPositionOffset)
        let defaultPosition = CGPoint(x: style.leftMargin, y: style.topMargin)
        return isPlaceholderAsHint ? hintPosition : defaultPosition
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupCommonElements()
    }

    public func configureInputView(inputiew: UIView!) {
        textInput.configureInputView(newInputView : inputiew)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupCommonElements()
    }

    override open var intrinsicContentSize : CGSize {
        let normalHeight = textInput.view.intrinsicContentSize.height
        return CGSize(width: UIView.noIntrinsicMetric, height: normalHeight + style.topMargin + style.bottomMargin)
    }

    open override func updateConstraints() {
        addLineViewConstraints()
        addTextInputConstraints()
        super.updateConstraints()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutPlaceholderLayer()
    }

    fileprivate func layoutPlaceholderLayer() {
        placeholderLayer.frame = CGRect(origin: placeholderPosition, size: CGSize(width: bounds.width, height: (style.textInputFont.pointSize * CGFloat(self.frameHeightCorrectionFactor)) ))
    }

    // MARK: Configuration

    fileprivate func addLineViewConstraints() {
        removeConstraints(constraints)
        lineView.removeConstraints(lineView.constraints)
        pinLeading(toLeadingOf: lineView, constant: style.leftMargin)
        pinTrailing(toTrailingOf: lineView, constant: style.rightMargin)
        lineView.setHeight(to: style.lineHeight)
        let constant = hasCounterLabel ? -counterLabel.intrinsicContentSize.height - counterLabelTopMargin : 0
        pinBottom(toBottomOf: lineView, constant: constant)
    }

    fileprivate func addTextInputConstraints() {
        pinLeading(toLeadingOf: textInput.view, constant: style.leftMargin)
        pinTrailing(toTrailingOf: textInput.view, constant: style.rightMargin)
        pinTop(toTopOf: textInput.view, constant: style.topMargin)
        textInput.view.pinBottom(toTopOf: lineView, constant: style.bottomMargin)
    }

    fileprivate func setupCommonElements() {
        addLine()
        addPlaceHolder()
        addTapGestureRecognizer()
        addTextInput()
    }

    fileprivate func addLine() {
        lineView.defaultColor = style.inactiveColor
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
    }

    fileprivate func addPlaceHolder() {
        placeholderLayer.masksToBounds = false
        placeholderLayer.string = placeHolderText
        placeholderLayer.foregroundColor = style.placeholderInactiveColor.cgColor
        placeholderLayer.fontSize = style.textInputFont.pointSize
        placeholderLayer.font = style.textInputFont
        placeholderLayer.contentsScale = UIScreen.main.scale
        placeholderLayer.backgroundColor = UIColor.clear.cgColor
        // Some letters like 'g' or 'á' were not rendered properly, the frame need to be about 20% higher than the font size
        let frameHeightCorrectionFactor: CGFloat = 1.2
        placeholderLayer.frame = CGRect(origin: placeholderPosition, size: CGSize(width: bounds.width, height: fontSize * frameHeightCorrectionFactor))
        layer.addSublayer(placeholderLayer)
    }

    fileprivate func addTapGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func addTextInput() {
        textInput = AnimatedTextInputFieldConfigurator.configure(with: type)
        textInput.textInputDelegate = self
        textInput.view.tintColor = style.activeColor
        textInput.textColor = style.textInputFontColor
        textInput.font = style.textInputFont
        var paddingView = UIView(frame:CGRect(x: 0, y: 0, width: 30, height: 30))
        textInput.autocorrection = autocorrection
        textInput.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textInput.view)
        invalidateIntrinsicContentSize()
    }

    fileprivate func updateCounter() {
        guard let counterText = counterLabel.text else { return }
        let components = counterText.components(separatedBy: "/")
        let characters = (text != nil) ? text!.count : 0
        counterLabel.text = "\(characters)/\(components[1])"
    }

    //MARK: States and animations

    fileprivate func configurePlaceholderAsActiveHint() {
        isPlaceholderAsHint = true
        configurePlaceholderWith(fontSize: style.placeholderMinFontSize,
                                 foregroundColor: style.activeColor.cgColor,
                                 text: placeHolderText)
        lineView.fillLine(with: style.lineActiveColor)
    }

    fileprivate func configurePlaceholderAsInactiveHint() {
        isPlaceholderAsHint = true
        configurePlaceholderWith(fontSize: style.placeholderMinFontSize,
                                 foregroundColor: style.inactiveColor.cgColor,
                                 text: placeHolderText)
        lineView.animateToInitialState()
    }

    fileprivate func configurePlaceholderAsDefault() {
        isPlaceholderAsHint = false
        configurePlaceholderWith(fontSize: style.textInputFont.pointSize,
                                 foregroundColor: style.placeholderInactiveColor.cgColor,
                                 text: placeHolderText)
        lineView.animateToInitialState()
    }

    fileprivate func configurePlaceholderAsErrorHint() {
        isPlaceholderAsHint = true
        configurePlaceholderWith(fontSize: style.placeholderMinFontSize,
                                 foregroundColor: style.errorColor.cgColor,
                                 text: placeholderErrorText)
        lineView.fillLine(with: style.errorColor)
    }

    fileprivate func configurePlaceholderWith(fontSize: CGFloat, foregroundColor: CGColor, text: String) {
        placeholderLayer.fontSize = fontSize
        placeholderLayer.foregroundColor = foregroundColor
        placeholderLayer.string = text
        textInput.view.accessibilityLabel = text
        layoutPlaceholderLayer()
        placeholderLayer.frame = CGRect(origin: placeholderPosition, size: placeholderLayer.frame.size)
    }

    fileprivate func animatePlaceholder(to applyConfiguration: () -> Void) {
        let duration = 0.2
        let function = CAMediaTimingFunction(controlPoints: 0.3, 0.0, 0.5, 0.95)
        transactionAnimation(with: duration, timingFuncion: function, animations: applyConfiguration)
    }

    //MARK: Behaviours

    @objc fileprivate func viewWasTapped(_ sender: UIGestureRecognizer) {
        if let tapAction = tapAction { tapAction() }
        else { becomeFirstResponder() }
    }

    fileprivate func styleDidChange() {
        lineView.defaultColor = style.lineInactiveColor
        placeholderLayer.foregroundColor = style.placeholderInactiveColor.cgColor
        let fontSize = style.textInputFont.pointSize
        placeholderLayer.fontSize = fontSize
        placeholderLayer.font = style.textInputFont
        placeholderLayer.frame = CGRect(origin: placeholderPosition, size: CGSize(width: bounds.width, height: fontSize))
        textInput.view.tintColor = style.activeColor
        textInput.textColor = style.textInputFontColor
        textInput.font = style.textInputFont
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    override open func becomeFirstResponder() -> Bool {
        isActive = true
        textInput.view.becomeFirstResponder()
        counterLabel.textColor = style.activeColor
        animatePlaceholder(to: configurePlaceholderAsActiveHint)
        return true
    }

    override open func resignFirstResponder() -> Bool {
        isActive = false
        textInput.view.resignFirstResponder()
        counterLabel.textColor = style.inactiveColor

        if let textInputError = textInput as? TextInputError {
            textInputError.removeErrorHintMessage()
        }

        guard let text = textInput.currentText , !text.isEmpty else {
            animatePlaceholder(to: configurePlaceholderAsDefault)
            return true
        }
        animatePlaceholder(to: configurePlaceholderAsInactiveHint)
        return true
    }



    override open var canResignFirstResponder : Bool {
        return textInput.view.canResignFirstResponder
    }

    override open var canBecomeFirstResponder : Bool {
        return textInput.view.canBecomeFirstResponder
    }

    open func show(error errorMessage: String, placeholderText: String? = nil) {
        placeholderErrorText = errorMessage
        if let textInput = textInput as? TextInputError {
            textInput.configureErrorState(with: placeholderText)
        }
        animatePlaceholder(to: configurePlaceholderAsErrorHint)
    }

    fileprivate func configureType() {
        textInput.view.removeFromSuperview()
        addTextInput()
    }

    fileprivate func configureStyle() {
        styleDidChange()
        if isActive {
            configurePlaceholderAsActiveHint()
        } else {
            isPlaceholderAsHint ? configurePlaceholderAsInactiveHint() : configurePlaceholderAsDefault()
        }
    }

    open func showCharacterCounterLabel(with maximum: Int? = nil) {
        hasCounterLabel = true
        let characters = (text != nil) ? text!.count : 0
        if let maximumValue = maximum {
            counterLabel.text = "\(characters)/\(maximumValue)"
        } else {
            counterLabel.text = "\(characters)"
        }
        counterLabel.textColor = isActive ? style.activeColor : style.inactiveColor
        counterLabel.font = style.counterLabelFont
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(counterLabel)
        addCharacterCounterConstraints()
        invalidateIntrinsicContentSize()
    }

    fileprivate func addCharacterCounterConstraints() {
        lineView.pinBottom(toTopOf: counterLabel, constant: counterLabelTopMargin)
        pinTrailing(toTrailingOf: counterLabel, constant: counterLabelRightMargin)
    }

    open func removeCharacterCounterLabel() {
        counterLabel.removeConstraints(counterLabel.constraints)
        counterLabel.removeFromSuperview()
        lineToBottomConstraint.constant = 0
        invalidateIntrinsicContentSize()
    }
}

extension AnimatedTextInput: TextInputDelegate {

    public func textInputDidBeginEditing(_ textInput: TextInput) {
        becomeFirstResponder()
        delegate?.animatedTextInputDidBeginEditing?(self)
    }

    public func textInputDidEndEditing(_ textInput: TextInput) {
        resignFirstResponder()
        delegate?.animatedTextInputDidEndEditing?(self)
    }

    public func textInputDidChange(_ textInput: TextInput) {
        updateCounter()
        sendActions(for: .editingChanged)
        delegate?.animatedTextInputDidChange?(animatedTextInput: self)
    }

    public func textInput(_ textInput: TextInput, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return delegate?.animatedTextInput?(self, shouldChangeCharactersInRange: range, replacementString: string) ?? true
    }

    public func textInputShouldBeginEditing(_ textInput: TextInput) -> Bool {
        return delegate?.animatedTextInputShouldBeginEditing?(self) ?? true
    }

    public func textInputShouldEndEditing(_ textInput: TextInput) -> Bool {
        return delegate?.animatedTextInputShouldEndEditing?(self) ?? true
    }

    public func textInputShouldReturn(_ textInput: TextInput) -> Bool {
        return delegate?.animatedTextInputShouldReturn?(self) ?? true
    }
}

@objc public protocol TextInput {
    var view: UIView { get }
    var currentText: String? { get set }
    var font: UIFont? { get set }
    var textColor: UIColor? { get set }
    var textAttributes: [NSAttributedString.Key: Any]? { get set }
    var textInputDelegate: TextInputDelegate? { get set }
    var currentSelectedTextRange: UITextRange? { get set }
    var currentBeginningOfDocument: UITextPosition? { get }
    var currentKeyboardAppearance: UIKeyboardAppearance { get set }
    var contentInset: UIEdgeInsets { get set }
    var autocorrection: UITextAutocorrectionType {get set}
    @available(iOS 10.0, *)
    var currentTextContentType: UITextContentType { get set }

    func configureInputView(newInputView: UIView)
    func changeReturnKeyType(with newReturnKeyType: UIReturnKeyType)
    func currentPosition(from: UITextPosition, offset: Int) -> UITextPosition?
    func changeClearButtonMode(with newClearButtonMode: UITextField.ViewMode)
}

@objc public protocol TextInputDelegate: class {
    func textInputDidBeginEditing(_ textInput: TextInput)
    func textInputDidEndEditing(_ textInput: TextInput)
    func textInputDidChange(_ textInput: TextInput)
    func textInput(_ textInput: TextInput, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    func textInputShouldBeginEditing(_ textInput: TextInput) -> Bool
    func textInputShouldEndEditing(_ textInput: TextInput) -> Bool
    func textInputShouldReturn(_ textInput: TextInput) -> Bool
}

public protocol TextInputError {
    func configureErrorState(with message: String?)
    func removeErrorHintMessage()
}
