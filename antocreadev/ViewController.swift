import UIKit
import CoreLocation

// MARK: - Modèles de données
struct WeatherModel {
    let cityName: String
    let temperature: Double
    let description: String
    let iconCode: String
    
    // Constructeur à partir des données API
    init?(from apiResponse: [String: Any]) {
        // Vérification et extraction des données nécessaires
        guard let main = apiResponse["main"] as? [String: Any],
              let temp = main["temp"] as? Double,  // Déjà en Celsius car units=metric dans l'URL
              let weatherArray = apiResponse["weather"] as? [[String: Any]],
              let weather = weatherArray.first,
              let description = weather["description"] as? String,
              let iconCode = weather["icon"] as? String,
              let cityName = apiResponse["name"] as? String else {
            return nil
        }
        
        self.cityName = cityName
        self.temperature = temp
        self.description = description
        self.iconCode = iconCode
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // Propriétés pour les éléments d'interface
    private var cityLabel: UILabel!
    private var weatherImageView: UIImageView!
    private var temperatureLabel: UILabel!
    private var descriptionLabel: UILabel!
    
    // Location Manager pour la géolocalisation
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    // Couleurs de background selon l'heure
    private let morningColor = UIColor(hexString: "#FFD700") // 6h - 12h
    private let afternoonColor = UIColor(hexString: "#FFA500") // 12h - 18h
    private let eveningColor = UIColor(hexString: "#FF8C00") // 18h - 21h
    private let nightColor = UIColor(hexString: "#2C3E50") // 21h - 6h
    
    private var gradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupLocationManager()
        startLocationUpdates()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Précision suffisante pour la météo
        locationManager.requestWhenInUseAuthorization() // Demander l'autorisation
    }
    
    private func startLocationUpdates() {
        // Vérifier le statut d'autorisation
        let authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            // Attendre la réponse de l'utilisateur à la demande d'autorisation
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showErrorAlert(message: "L'accès à la localisation est nécessaire pour obtenir la météo locale. Veuillez l'activer dans les paramètres.")
            // Par défaut, utiliser une ville
            fetchWeatherDataForCity("Paris")
        @unknown default:
            showErrorAlert(message: "Statut d'autorisation inconnu")
            fetchWeatherDataForCity("Paris")
        }
    }
    
    // Méthode delegate appelée lorsque l'autorisation change
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            showErrorAlert(message: "L'accès à la localisation est nécessaire pour obtenir la météo locale. Veuillez l'activer dans les paramètres.")
            // Par défaut, utiliser une ville
            fetchWeatherDataForCity("Paris")
        default:
            break
        }
    }
    
    // Méthode delegate appelée lorsqu'une position est obtenue
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            manager.stopUpdatingLocation() // Arrêter les mises à jour pour économiser la batterie
            currentLocation = location
            fetchWeatherDataForLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    // Gestion des erreurs de localisation
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erreur de localisation: \(error.localizedDescription)")
        showErrorAlert(message: "Impossible d'obtenir votre position. Vérifiez que la localisation est activée.")
        // Par défaut, utiliser une ville
        fetchWeatherDataForCity("Paris")
    }

    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        updateBackgroundColorBasedOnTime()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func updateBackgroundColorBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        var topColor: UIColor
        var bottomColor: UIColor
        
        switch hour {
        case 6..<12: // Matin (6h - 12h)
            topColor = morningColor
            bottomColor = morningColor.withAlphaComponent(0.7)
        case 12..<18: // Après-midi (12h - 18h)
            topColor = afternoonColor
            bottomColor = afternoonColor.withAlphaComponent(0.7)
        case 18..<21: // Soirée (18h - 21h)
            topColor = eveningColor
            bottomColor = eveningColor.withAlphaComponent(0.7)
        default: // Nuit (21h - 6h)
            topColor = nightColor
            bottomColor = nightColor.withAlphaComponent(0.7)
        }
        
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
    }

    private func setupUI() {
        // Ville Label
        cityLabel = UILabel()
        cityLabel.text = "Chargement..."
        cityLabel.font = UIFont.boldSystemFont(ofSize: 32)
        cityLabel.textColor = .white
        cityLabel.textAlignment = .center
        cityLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cityLabel)

        // Image météo
        weatherImageView = UIImageView(image: UIImage(systemName: "cloud"))
        weatherImageView.tintColor = .white
        weatherImageView.contentMode = .scaleAspectFit
        weatherImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weatherImageView)

        // Température Label
        temperatureLabel = UILabel()
        temperatureLabel.text = "--°C"
        temperatureLabel.font = UIFont.boldSystemFont(ofSize: 48)
        temperatureLabel.textColor = .white
        temperatureLabel.textAlignment = .center
        temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(temperatureLabel)

        // Description Météo Label
        descriptionLabel = UILabel()
        descriptionLabel.text = "Chargement..."
        descriptionLabel.font = UIFont.systemFont(ofSize: 24)
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        // Bouton Refresh
        let refreshButton = UIButton(type: .system)
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.tintColor = .white
        refreshButton.contentVerticalAlignment = .fill
        refreshButton.contentHorizontalAlignment = .fill
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)

        // Contraintes
        NSLayoutConstraint.activate([
            cityLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            weatherImageView.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 32),
            weatherImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherImageView.heightAnchor.constraint(equalToConstant: 100),
            weatherImageView.widthAnchor.constraint(equalToConstant: 100),

            temperatureLabel.topAnchor.constraint(equalTo: weatherImageView.bottomAnchor, constant: 16),
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 8),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            refreshButton.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // Fonction pour récupérer les données météo par ville (fallback)
    private func fetchWeatherDataForCity(_ city: String) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&units=metric&appid=b8c0162f208b810fd4c2e82e370a98a4"
        
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else {
            print("URL invalide")
            return
        }
        
        performWeatherRequest(with: url)
    }
    
    // Fonction pour récupérer les données météo par coordonnées
    private func fetchWeatherDataForLocation(latitude: Double, longitude: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&appid=b8c0162f208b810fd4c2e82e370a98a4"
        
        guard let url = URL(string: urlString) else {
            print("URL invalide")
            return
        }
        
        performWeatherRequest(with: url)
    }
    
    // Exécution de la requête HTTP
    private func performWeatherRequest(with url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Erreur lors de la requête: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "Impossible de récupérer les données météo")
                }
                return
            }
            
            guard let data = data else {
                print("Aucune donnée reçue")
                
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "Aucune donnée reçue")
                }
                return
            }
            
            self?.parseWeatherData(data)
        }
        
        task.resume()
    }
    
    // Fonction pour analyser les données météo (exécutée sur un thread de fond)
    private func parseWeatherData(_ data: Data) {
        do {
            // Convertir les données JSON en dictionnaire
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Transformer les données brutes en modèle adapté
                if let weatherModel = WeatherModel(from: json) {
                    // IMPORTANT: Mise à jour de l'UI toujours sur le thread principal
                    DispatchQueue.main.async { [weak self] in
                        self?.updateUI(with: weatherModel)
                    }
                } else {
                    print("Impossible de créer le modèle à partir des données reçues")
                    
                    // Afficher une erreur sur le thread principal
                    DispatchQueue.main.async { [weak self] in
                        self?.showErrorAlert(message: "Format de données incorrect")
                    }
                }
            }
        } catch {
            print("Erreur lors du parsing JSON: \(error.localizedDescription)")
            
            // Afficher une erreur sur le thread principal
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAlert(message: "Erreur lors de l'analyse des données")
            }
        }
    }
    
    // Fonction pour afficher une alerte d'erreur
    private func showErrorAlert(message: String) {
        // Cette méthode doit toujours être appelée sur le thread principal
        let alert = UIAlertController(title: "Erreur", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // Fonction pour mettre à jour l'interface avec le modèle
    // Cette fonction doit toujours être appelée sur le thread principal
    private func updateUI(with model: WeatherModel) {
        cityLabel.text = model.cityName
        temperatureLabel.text = "\(Int(round(model.temperature)))°C"
        
        // Première lettre en majuscule pour la description
        let formattedDescription = model.description.prefix(1).uppercased() + model.description.dropFirst()
        descriptionLabel.text = formattedDescription
        
        // Mise à jour de l'icône météo
        updateWeatherIcon(iconCode: model.iconCode)
        
        // Mise à jour de la couleur du fond selon l'heure actuelle
        updateBackgroundColorBasedOnTime()
    }
    
    // Fonction pour mettre à jour l'icône météo
    // Cette fonction doit toujours être appelée sur le thread principal
    private func updateWeatherIcon(iconCode: String) {
        // Correspondance entre les codes API OpenWeather et les SF Symbols
        var systemIconName = "cloud"
        
        switch iconCode {
        case "01d", "01n": // ciel clair
            systemIconName = "sun.max"
        case "02d", "02n": // quelques nuages
            systemIconName = "cloud.sun"
        case "03d", "03n": // nuages épars
            systemIconName = "cloud"
        case "04d", "04n": // nuages
            systemIconName = "cloud.fill"
        case "09d", "09n": // pluie modérée
            systemIconName = "cloud.drizzle"
        case "10d", "10n": // pluie
            systemIconName = "cloud.rain"
        case "11d", "11n": // orage
            systemIconName = "cloud.bolt"
        case "13d", "13n": // neige
            systemIconName = "cloud.snow"
        case "50d", "50n": // brouillard
            systemIconName = "cloud.fog"
        default:
            systemIconName = "cloud"
        }
        
        weatherImageView.image = UIImage(systemName: systemIconName)
    }

    @objc private func refreshTapped() {
        print("Rafraîchir l'interface météo...")
        
        // Indiquer à l'utilisateur que le rafraîchissement est en cours
        cityLabel.text = "Actualisation..."
        descriptionLabel.text = "Chargement..."
        
        // Mettre à jour la couleur du fond
        updateBackgroundColorBasedOnTime()
        
        // Relancer la géolocalisation
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            // Si la géolocalisation n'est pas disponible, utiliser la dernière position connue
            if let location = currentLocation {
                fetchWeatherDataForLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            } else {
                // En dernier recours, utiliser une ville par défaut
                fetchWeatherDataForCity("Paris")
            }
        }
    }
}

// Extension pour faciliter l'utilisation des couleurs hexadécimales
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
