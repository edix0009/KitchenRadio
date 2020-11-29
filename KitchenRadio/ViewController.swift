import UIKit
import AVKit
import MediaPlayer

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

    var slideGesture = UIPanGestureRecognizer()
    
    
    @IBOutlet weak var bg: UIImageView!
    @IBOutlet weak var buttonCollaction: UIStackView!
    @IBOutlet var container: UIView!
    
    let volumeView = MPVolumeView()
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    var currentStation: Int? = 1
    var timer = Timer()

    @IBOutlet weak var menuBarStack: UIStackView!
    @IBOutlet weak var wrapperViewAlbumArt: UIView!
    @IBOutlet weak var albumArtworkView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("stated :)")
        stations = loadStationsFromJSON(from: "stations")
        
        stationButtons = getSubviewsOf(view: self.container).filter{$0.tag >= 0}
//        initProgramButtons(buttons: stationButtons!, stations: stations!)
        
        player = RadioPlayer(stations: stations!)
        

//        slideGesture = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
//        slideGesture.maximumNumberOfTouches = 1
//        container.addGestureRecognizer(slideGesture)
        
        
        // Three finger tap gesture to reset stations
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap))
        gesture.numberOfTapsRequired = 3
        container.addGestureRecognizer(gesture)
     
        // Init timers
        scheduledRadioReset()
        scheduledNowPlayingUpdate()
        
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
    }

    
    @objc func menuItemTouched(_ sender: UIButton) {
        print("Tocuhed! :D")
        
        getSubviewsOf(view: self.menuBarStack)
            .filter{ $0 is UIButton }
            .forEach{ resetMenuItemStyle(button: $0 as! UIButton) }
        
        sender.backgroundColor = UIColor.white
        sender.layer.cornerRadius = 20
        sender.layer.shadowColor = UIColor.black.cgColor
        sender.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        sender.layer.shadowRadius = 14
        sender.layer.shadowOpacity = 0.46
        sender.setTitleColor(UIColor.black.withAlphaComponent(0.70), for: .normal)
        
        player?.play(program: sender.tag)
        currentStation = sender.tag
        setNowPlayingIndicator(button: sender)
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(setCurrentInformation), with: nil, afterDelay: 1)
    }
    
    func updateNowPlayingInformation(url: String) {
        NowPlaying.GetCurrentTrack(url: url) { track in
            DispatchQueue.main.async {
                let itunesQuery = track.name + " " + track.artist
                NowPlaying.GetArtwork(query: itunesQuery) { albumImage in
                    DispatchQueue.main.async { [self] in
                        self.artistLabel.text = track.artist
                        self.trackLabel.text = track.name
                        self.albumArtworkView.image = albumImage
                    }
                }

                
            }
        }
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
    
    @objc func setCurrentInformation() {
        let url = stations![currentStation!].playlistURL
        updateNowPlayingInformation(url: url)
    }
    
    @objc func handleThreeFingerTap() {
        player?.reset(stations: stations!)
        player?.play(program: currentStation ?? 1)
    }
    
//    func initProgramButtons(buttons: [UIButton], stations: [RadioStation]) {
//
//        for (index, button) in buttons.enumerated() {
//            let buttonWidth = button.frame.size.width
//            let programImage = UIImage(named: stations[index].imageAsset)?.resized(withPercentage: buttonWidth/360)
//
//
//            button.setImage(programImage, for: .normal)
//            button.backgroundColor = hexStringToUIColor(hex: stations[index].tileColor)
//            button.setTitleColor(UIColor.white, for: .highlighted)
//            button.setTitleColor(UIColor.white, for: .focused)
//            button.setTitleColor(UIColor.white, for: .selected)
//            button.imageView?.contentMode = .scaleAspectFit
//
//        }
//
//    }

    var prev:CGFloat = 0.0
    @objc func panDetected(sender : UIPanGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.view)
        let vol = AVAudioSession.sharedInstance().outputVolume

        if (touchPoint.x < (prev - 10)) {
            if let view = volumeView.subviews.first as? UISlider { view.value = vol - 0.05 }
            prev = touchPoint.x
        } else if (touchPoint.x > (prev + 10)) {
            if let view = volumeView.subviews.first as? UISlider { view.value = vol + 0.05}
            prev = touchPoint.x
        }
        
    }
    
    
//    @IBAction func programTouched(_ sender: UIButton) {
//        print(1)
//        player?.play(program: sender.tag)
//        currentStation = sender.tag
//        setNowPlayingIndicator(button: sender)
//
//        stationButtons?.forEach { setButtonShadow(button: $0, opacity: 0.13, blur: 10) }
//        setButtonShadow(button: sender)
//    }
    
//    func setButtonShadow(button: UIButton, opacity: Float = 0.5, blur: CGFloat = 30.0) {
//
//        UIView.transition(with: button,
//                          duration: 0.2,
//                          options: .transitionCrossDissolve,
//                          animations: {
//                            button.layer.shadowColor = UIColor.black.cgColor
//                            button.layer.shadowOffset = CGSize(width: 0.0, height: 6.0)
//                            button.layer.shadowRadius = blur
//                            button.layer.shadowOpacity = opacity
//                          },
//                          completion: nil)
//    }
    
    @IBOutlet weak var bgView: UIView!
    
    func setNowPlayingIndicator(button: UIButton) {
        self.bgView.backgroundColor = hexStringToUIColor(hex: stations![button.tag].tileColor)
    }
    
    func loadStationsFromJSON(from: String) -> [RadioStation]? {
        var stations:[RadioStation]?
        
        DataManager.getDataFromFileWithSuccess(file: from) { (data) in
            guard let data = data,
                let jsonDictionary = try? JSONDecoder().decode([String: [RadioStation]].self, from: data),
                let stationsArray = jsonDictionary["station"]
                else {print("JSON Station Loading Error")
                return
            }
            stations = stationsArray
        }
        
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

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIButton {
    func loadingIndicator(_ show: Bool) {
        let tag = 808404
        if show {
            self.isEnabled = false
            self.alpha = 0.5
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = tag
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            self.isEnabled = true
            self.alpha = 1.0
            if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}

public extension UIImage {

    /// Tint, Colorize image with given tint color
    /// This is similar to Photoshop's "Color" layer blend mode
    /// This is perfect for non-greyscale source images, and images that
    /// have both highlights and shadows that should be preserved<br><br>
    /// white will stay white and black will stay black as the lightness of
    /// the image is preserved
    ///
    /// - Parameter TintColor: Tint color
    /// - Returns:  Tinted image
    public func tintImage(with fillColor: UIColor) -> UIImage {
        
        return modifiedImage { context, rect in
            // draw black background - workaround to preserve color of partially transparent pixels
            context.setBlendMode(.normal)
            UIColor.black.setFill()
            context.fill(rect)
            
            // draw original image
            context.setBlendMode(.normal)
            context.draw(cgImage!, in: rect)
            
            // tint image (loosing alpha) - the luminosity of the original image is preserved
            context.setBlendMode(.color)
            fillColor.setFill()
            context.fill(rect)
            
            // mask by alpha values of original image
            context.setBlendMode(.destinationIn)
            context.draw(context.makeImage()!, in: rect)
        }
    }
    
    /// Modified Image Context, apply modification on image
    ///
    /// - Parameter draw: (CGContext, CGRect) -> ())
    /// - Returns:        UIImage
    fileprivate func modifiedImage(_ draw: (CGContext, CGRect) -> ()) -> UIImage {
        
        // using scale correctly preserves retina images
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context: CGContext! = UIGraphicsGetCurrentContext()
        assert(context != nil)
        
        // correctly rotate image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        
        draw(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIColor {

    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
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

extension UIView{
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}



