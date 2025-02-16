//
//  ViewController.swift
//  antocreadev
//
//  Created by antocreadev on 06/02/2025.
//

// ------ IMPORT
import UIKit

// ------ EXTENSION
// --- Test extension pour changer le X, Y d'une frame
extension UIView {
    func setX(_ x: CGFloat) {
        self.frame = CGRect(x: x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
    }
    
    func setY(_ y: CGFloat) {
        self.frame = CGRect(x: self.frame.origin.x, y: y, width: self.frame.size.width, height: self.frame.size.height)
    }
}
// --- Extension pour avoir des couleur en hexadecimal
// ref : https://stackoverflo.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
extension UIColor {
    convenience init(_ hex: String) {
        // supprime les espaces blancs
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // supprime le "#"
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        
        // Fait la conversion
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb) // met le hexadecimal entier 64
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                 green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                 blue: CGFloat(rgb & 0x0000FF) / 255.0,
                 alpha: 1.0)
    }
}

// ------ MAIN
class ViewController: UIViewController {

    // ------ COMPOSANTS
    // --- Exemple d'un composant bouton
    private let btn : UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 50, y: 100, width: 200, height: 50)
        button.backgroundColor = .systemBlue
        
        return button
    }()

    // --- Composant gradient (lazy fonctionne qu'avec var, il permet d'avoir self car il se fait après l'initalisation (au besoin))
    private lazy var gradient : CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor("#007BFF").cgColor, UIColor("#BA4CE4").cgColor]
        
        return gradientLayer
    }()
    
    // --- Composant du nuage
    private lazy var cloudImageView : UIImageView = {
        let cloudImageView = UIImageView()
        cloudImageView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 100)
        cloudImageView.backgroundColor = .systemYellow
        cloudImageView.image = UIImage(systemName: "cloud.sun.fill")
        cloudImageView.contentMode = .scaleAspectFit
        cloudImageView.tintColor = .white
        
        return cloudImageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.insertSublayer(gradient, at: 0)
        view.addSubview(btn)
        btn.setX(100)
        let title = UILabel()
        title.frame = CGRect(x: 50, y: 100, width: 200, height: 50)
        title.backgroundColor = .systemBlue
        title.setX(100)
        title.setY(200)
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.text = "Utilisation des frames"
        view.addSubview(title)
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 100, y: 300, width: 200, height: 50)
        button.backgroundColor = .systemRed
        button.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(button)
        
        let button2 = UIButton(type: .system)
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.backgroundColor = .systemGreen
        view.addSubview(button2)
        NSLayoutConstraint.activate([
        button2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        button2.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        button2.widthAnchor.constraint(equalToConstant: 200),
        button2.heightAnchor.constraint(equalToConstant: 50)
        ])
        

        self.view.addSubview(cloudImageView)

        
    }
}

