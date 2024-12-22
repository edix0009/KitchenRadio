import UIKit
import AVKit
import MediaPlayer
import UIImageColors
//import swift_vibrant


extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.layer.cornerRadius = 28
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}

class ViewController: UIViewController {

    @IBOutlet var container: UIView!
    
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    var currentStation: Int? = 0
    var currentTrack: KRTrack?
    var timer = Timer()
    var workItem: DispatchWorkItem?
    
    // Gaint hack this shouldn't work
    var workItemOrder = 0

    @IBOutlet weak var menuBarStack: UIStackView!
    @IBOutlet weak var wrapperViewAlbumArt: UIView!
    @IBOutlet weak var albumArtworkView: UIImageView!
    @IBOutlet weak var fullTrackLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var addToSpotifyButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var clockLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("stated :)")
        
        stations = loadStationsFromJSON(from: "stations")
        stationButtons = getSubviewsOf(view: self.container).filter{$0.tag >= 0}
        player = RadioPlayer(stations: stations!)
        
        // Three finger tap gesture to reset stations
        // let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap))
        // gesture.numberOfTapsRequired = 3
        // container.addGestureRecognizer(gesture)
     
        // Init timers
        scheduledRadioReset()
        scheduledNowPlayingUpdate()
        clockTicker()
        
        
        
        
        // Init play buttons
        menuBarStack.addBackground(color: UIColor.black.withAlphaComponent(0.60))
        
        getSubviewsOf(view: self.menuBarStack)
            .filter{ $0 is UIButton }
            .forEach({
                ($0 as! UIButton).addTarget(self, action: "menuItemTouched:", for: .touchDown)
            })
        
        // Init 'now playing' section
        wrapperViewAlbumArt.clipsToBounds = false
        wrapperViewAlbumArt.layer.cornerRadius = 10
        wrapperViewAlbumArt.layer.masksToBounds = false
        wrapperViewAlbumArt.layer.shadowColor = UIColor.black.cgColor
        wrapperViewAlbumArt.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        wrapperViewAlbumArt.layer.shadowRadius = 30
        wrapperViewAlbumArt.layer.shadowOpacity = 0.50
        
        albumArtworkView.clipsToBounds = true
        albumArtworkView.layer.cornerRadius = 10
        
        addToSpotifyButton.backgroundColor = UIColor.black.withAlphaComponent(0.60)
        addToSpotifyButton.layer.cornerRadius = 28
        
        leftButton.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        leftButton.layer.cornerRadius = 28
        
        initGradients()
        
        workItem = DispatchWorkItem { self.setCurrentInformation() }
    }
    
    
    @IBAction func setQRCode(_ sender: Any) {
//        currentTrack?.name = "QRCODE"
//        albumArtworkView.image = UIImage(named: "qrCodespotifyPlaylist")
        
        // Just reset the radio instead
        
        player?.reset(stations: stations!)
        player?.play(program: currentStation ?? 1)
    }
    
    
    @IBAction func prev(_ sender: Any) {
        let selected = (currentStation!-1)
        let nextStation = selected < 0 ? (self.menuBarStack.subviews.count-2) : selected
        
        let stationButton = getSubviewsOf(view: self.menuBarStack)
            .filter{ $0 is UIButton }
            .filter{ $0.tag == nextStation }
            .first
        
        menuItemTouched(stationButton as! UIButton)
    }
    
    @IBAction func next(_ sender: Any) {
        let nextStation = ((currentStation!+1) % (self.menuBarStack.subviews.count-1))
        
        let stationButton = getSubviewsOf(view: self.menuBarStack)
            .filter{ $0 is UIButton }
            .filter{ $0.tag == nextStation }
            .first
        
        menuItemTouched(stationButton as! UIButton)
    }
    
    // my god is this a disgusting hack..
    var gradients: [CAGradientLayer] = []
    func initGradients() {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [hexStringToUIColor(hex: "2C0101").cgColor, UIColor(white: 0, alpha: 0.0).cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 5.5)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        
        let gradient2: CAGradientLayer = CAGradientLayer()
        gradient2.colors = [hexStringToUIColor(hex: "D9A6BF").cgColor, UIColor(white: 0, alpha: 0.0).cgColor]
        gradient2.locations = [0.0 , 1.0]
        gradient2.startPoint = CGPoint(x: 0.9, y: 1.1)
        gradient2.endPoint = CGPoint(x: 0.2, y: 0.0)
        gradient2.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        
        let gradient3: CAGradientLayer = CAGradientLayer()
        gradient3.colors = [hexStringToUIColor(hex: "9E745B").cgColor, UIColor(white: 0, alpha: 0.0).cgColor]
        gradient3.locations = [0.0 , 1.0]
        gradient3.startPoint = CGPoint(x: 0.8, y: 0)
        gradient3.endPoint = CGPoint(x: 0.4, y: 1.0)
        gradient3.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        self.bgView.layer.insertSublayer(gradient, at: 0)
        self.bgView.layer.insertSublayer(gradient2, at: 1)
        self.bgView.layer.insertSublayer(gradient3, at: 2)
        
        gradients = [gradient, gradient2, gradient3]
        
    }

    @IBAction func addToSpotify(_ sender: Any) {
        guard self.addToSpotifyButton.titleLabel?.text != "Added!" else { return }
        guard let track = currentTrack else { return }
        
        let trackQuery = track.name + " " + track.artist
        let cleanedTrackQuery = ItunesAPI.cleanRawMetadataIfNeeded(trackQuery)
        SpotifyAuth.addTrackToPlaylist(query: cleanedTrackQuery)
        addToSpotifyButton.setTitle("Added!", for: .normal)
        addToSpotifyButton.titleLabel?.font.withSize(25)
    }
    
    @objc func menuItemTouched(_ sender: UIButton) {
        
        getSubviewsOf(view: self.menuBarStack)
            .filter{ $0 is UIButton }
            .forEach{ resetMenuItemStyle(button: $0 as! UIButton) }
        
        sender.backgroundColor = UIColor.white
        sender.layer.cornerRadius = 19
        sender.layer.shadowColor = UIColor.black.cgColor
        sender.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        sender.layer.shadowRadius = 14
        sender.layer.shadowOpacity = 0.46
        sender.setTitleColor(UIColor.black.withAlphaComponent(0.70), for: .normal)
        
        currentStation = sender.tag
        player?.play(program: currentStation!)
        
        setCurrentInformation()
        //NSObject.cancelPreviousPerformRequests(withTarget: self)
        //perform(#selector(setCurrentInformation), with: nil, afterDelay: 1)
        
        
    }
    
    func updateNowPlayingInformation(url: String, order: Int) {
        NowPlaying.GetCurrentTrack(url: url) { track in
            DispatchQueue.main.async {
                
                guard track != self.currentTrack else { return }
                guard self.workItemOrder == order else { return }
                
                
                let itunesQuery = track.name + " " + track.artist
                NowPlaying.GetArtwork(query: itunesQuery) { albumImage in
                    DispatchQueue.main.async { [self] in
                        albumImage.getColors(quality: .low) { colors in
                            
                            guard workItemOrder == order else { return }
                            self.currentTrack = track
                            
                            self.fullTrackLabel.text = track.raw
                            self.artistLabel.text = formatArtist(artistName: track.artist)
                            self.trackLabel.text = track.name
                            self.albumArtworkView.image = albumImage
                            setBackgroundGradients(colors: colors!)
                        }
                        addToSpotifyButton.setTitle("Add to playlist", for: .normal)
                        addToSpotifyButton.titleLabel?.font.withSize(35)
                    }
                }
            }
        }
    }
    
    func formatArtist(artistName: String) -> String {
        
        var x = artistName
        let skipPatterns = [", ", ";", "& ", "(feat. ", "feat. ",
                            "ft. ", "Ft. ", " ft ", "/", " x "]
        
        skipPatterns.forEach { pattern in
            x.removingRegexMatches(pattern: pattern, replaceWith: "\n")
        }
        
        return x
    }
    
    func setBackgroundGradients(colors: UIImageColors) {
        
        let clearColor = UIColor(white: 0, alpha: 0.0).cgColor
        let colorList = [colors.background, colors.primary,
                         colors.secondary, colors.detail]
        
        let c = (colorList.first{isColorfulEnough(color: $0!)} ?? UIColor.gray)!.hsba
        
        
        let c1 = UIColor.init(hue: c.hue,
                              saturation: c.saturation+0.1,
                              brightness: c.brightness+0.1,
                              alpha: c.alpha).cgColor
        
        // Bottom Corner
        let c2 = UIColor.init(hue: c.hue+0.017,
                              saturation: c.saturation,
                              brightness: c.brightness+0.1,
                              alpha: c.alpha).cgColor
        
        // Top corner
        let c3 = UIColor.init(hue: c.hue-0.017,
                              saturation: c.saturation-0.1,
                              brightness: c.brightness-0.1,
                              alpha: c.alpha).cgColor
        
        
        gradients[0].colors = [c1, clearColor]
        gradients[1].colors = [c2, clearColor]
        gradients[2].colors = [c3, clearColor]
        
    }
    
    func isColorfulEnough(color: UIColor) -> Bool {
        print(color.hsba)
        let c = color.hsba
        return c.brightness > 0.3 && c.saturation > 0.3
    }
    
    func resetMenuItemStyle(button: UIButton) {
        button.backgroundColor = nil
        button.layer.shadowPath = nil
        button.setTitleColor(UIColor.white.withAlphaComponent(0.70), for: .normal)
    }
    
    func scheduledRadioReset(){
        timer = Timer.scheduledTimer(timeInterval: 18000, target: self, selector: #selector(handleThreeFingerTap), userInfo: nil, repeats: true)
    }

    func scheduledNowPlayingUpdate(){
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setCurrentInformation), userInfo: nil, repeats: true)
    }
    
    func clockTicker(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setClock), userInfo: nil, repeats: true)
    }
    
    @objc func setClock() {
        let date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let dateString = dateFormatter.string(from: date)
        clockLabel.text = dateString
    }
    
    @objc func setCurrentInformation() {
        let url = stations![currentStation!].playlistURL
        workItemOrder += 1
        updateNowPlayingInformation(url: url, order: workItemOrder)
    }
    
    @objc func handleThreeFingerTap() {
        player?.reset(stations: stations!)
        player?.play(program: currentStation ?? 1)
    }
    
    @IBOutlet weak var bgView: UIView!

    func loadStationsFromJSON(from: String) -> [RadioStation]? {
        var stations:[RadioStation]?
        print(1)
        DataManager.getDataFromFileWithSuccess(file: from) { (data) in
            guard let data = data,
                let jsonDictionary = try? JSONDecoder().decode([String: [RadioStation]].self, from: data),
                let stationsArray = jsonDictionary["station"]
                else {print("JSON Station Loading Error")
                return
            }
            stations = stationsArray
        }
        print(3)
        return stations
    }

    private func getSubviewsOf<T : UIView>(view:UIView) -> [T] {
        var subviews = [T]()
        
        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]
            
            if let subview = subview as? T {
                subviews.append(subview)
            }
        }
        
        return subviews
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

extension UIImageView {
    func applyshadowWithCorner(containerView : UIView, cornerRadious : CGFloat){
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowOffset = CGSize.zero
        containerView.layer.shadowRadius = 10
        containerView.layer.cornerRadius = cornerRadious
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: cornerRadious).cgPath
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadious
    }
}

extension UIColor {
    func tooDarkOrLight() -> Bool {
        guard let components = cgColor.components, components.count > 2 else { return false }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return (brightness > 0.8 || brightness < 0.2)
    }
}

extension String {
    mutating func removingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch { return }
    }
}

extension UIColor {
    var hsba:(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (hue: h, saturation: s, brightness: b, alpha: a)
    }
 }
