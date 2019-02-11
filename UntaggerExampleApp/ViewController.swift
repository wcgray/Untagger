import UIKit
import Untagger

let lightGray = UIColor(white: 215.0/255.0, alpha: 1)

extension UIView {
    func addDottedBorder() {
        let border = CAShapeLayer()
        border.strokeColor = lightGray.cgColor
        border.fillColor = nil;
        border.lineDashPattern = [4, 2]
        border.frame = self.bounds
        border.path = UIBezierPath(rect: self.bounds).cgPath
        self.layer.addSublayer(border)
    }
}

class ViewController: UIViewController, UITextFieldDelegate {
    let titleLabel = UILabel()
    let bodyLabel = UITextView()
    let bodyLabelPlaceholder = UILabel()
    let textField = UITextField()
    
    func setExtractedArticleValues(title: String?, body: String?) {
        if let title = title, title.count > 0 {
            self.titleLabel.textColor = UIColor.black
            self.titleLabel.text = title
        }
        
        bodyLabelPlaceholder.isHidden = (body ?? "").count > 0
        
        if let body = body, body.count > 0 {
            self.bodyLabel.text = body
        }
    }
    
    func hasTopSafeSpace() -> Bool {
        if #available(iOS 11.0,  *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        titleLabel.text = "Article Title..."
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textColor = lightGray
        titleLabel.frame = CGRect(x: 20, y: hasTopSafeSpace() ? 44 : 22, width: view.frame.size.width - 40, height: 44)
        view.addSubview(titleLabel)
        titleLabel.addDottedBorder()
        
        bodyLabel.font = UIFont.boldSystemFont(ofSize: 22)
        bodyLabel.isEditable = false
        bodyLabel.textColor = UIColor.black
        bodyLabel.frame = CGRect(x: 20, y: titleLabel.frame.origin.y + titleLabel.frame.size.height + 10, width: view.frame.size.width - 40, height: 176)
        let bodyBackgroundView = UIView()
        bodyBackgroundView.frame = bodyLabel.frame
        bodyBackgroundView.addDottedBorder()
        view.addSubview(bodyBackgroundView)
        view.addSubview(bodyLabel)
        
        bodyLabel.addDottedBorder()
        
        bodyLabelPlaceholder.text = "Article Body..."
        bodyLabelPlaceholder.textColor = lightGray
        bodyLabelPlaceholder.font = UIFont.boldSystemFont(ofSize: 32)
        bodyLabelPlaceholder.sizeToFit()
        bodyLabelPlaceholder.frame.origin = bodyLabel.frame.origin
        view.addSubview(bodyLabelPlaceholder)
        
        textField.font = UIFont.boldSystemFont(ofSize: 22)
        textField.placeholder = "Add url to extract"
        textField.delegate = self
        textField.frame = CGRect(x: 20, y: bodyLabel.frame.origin.y + bodyLabel.frame.size.height + 10, width: view.frame.size.width - 40 - 110, height: 44)
        view.addSubview(textField)
        textField.addDottedBorder()
        
        let extractArticleButton = UIButton()
        extractArticleButton.setTitle("Extract", for: .normal)
        extractArticleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        extractArticleButton.setTitleColor(UIColor.black, for: .normal)
        extractArticleButton.frame = CGRect(x: textField.frame.origin.x + textField.frame.size.width + 10, y: textField.frame.origin.y, width: 100, height: 44)
        extractArticleButton.layer.borderColor = UIColor.black.cgColor
        extractArticleButton.layer.borderWidth = 1
        extractArticleButton.addTarget(self, action: #selector(self.pressedExtract), for: .touchUpInside)
        view.addSubview(extractArticleButton)
    }
    
    @objc func pressedExtract() {
        extractArticle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textField.becomeFirstResponder()
    }
    
    func extractArticle() {
        if let text = self.textField.text, let url = URL(string: text) {
            UntaggerManager.sharedInstance.getText(url: url) { [weak self] (title, body, source, error) in
                self?.textField.text = nil
                self?.setExtractedArticleValues(title: title, body: body)
                
                if let error = error {
                    let alertController = UIAlertController(title: "Error", message: error.message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        extractArticle()
        
        return false
    }
}

