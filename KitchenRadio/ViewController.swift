import UIKit
import AVKit
import MediaPlayer
import SwiftSoup

class ViewController: UIViewController {

    var slideGesture = UIPanGestureRecognizer()
    
    // Main button collection
    @IBOutlet weak var buttonCollaction: UIStackView!
    @IBOutlet var container: UIView!
    
    let volumeView = MPVolumeView()
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    
    var workItem: DispatchWorkItem?
    
    // Control panel
    var currentStation: RadioStation?
    
    @IBOutlet weak var controlStackView: UIStackView!
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    
    let dateFormatter = DateFormatter()
    var clock = Timer()
    @IBOutlet weak var clockLabel: UILabel!
    
    @IBOutlet weak var resetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stations = loadStationsFromJSON(from: "stations")
        currentStation = stations?.first
        
        stationButtons = getSubviewsOf(view: buttonCollaction).filter{$0 is UIButton}
            initProgramButtons(buttons: stationButtons!, stations: stations!)
        
        player = RadioPlayer(stations: stations!)
        
        controlStackView.addBackground(color: hexStringToUIColor(hex: "#1B1B1B"))
        
        dateFormatter.dateFormat = "HH:mm"
        clock = Timer.scheduledTimer(timeInterval: 12.0, target: self, selector:#selector(self.tick) , userInfo: nil, repeats: true)
        tick()

        slideGesture = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
        slideGesture.maximumNumberOfTouches = 1
        container.addGestureRecognizer(slideGesture)
        
        
        // Three finger tap gesture to reset stations
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap(sender:)))
        gesture.numberOfTapsRequired = 3
        container.addGestureRecognizer(gesture)
        
    }
    
    @objc func tick() {
        clockLabel.text = dateFormatter.string(from: Date())
        
//        let trackinfo = NowPlayingInfo.getTrackInfo(url: (self.currentStation?.playlistURL)!)!
//        FRadioAPI.getArtwork(for: trackinfo, size: 300, completionHandler: self.setArtwork(url:artist:track:))
        if workItem != nil {
            workItem!.cancel()
        }
        
        workItem = DispatchWorkItem {
            
            let trackinfo = NowPlayingInfo.getTrackInfo(url: (self.currentStation?.playlistURL)!)!
            
            DispatchQueue.main.async {
                FRadioAPI.getArtwork(for: trackinfo, size: 300, completionHandler: self.setArtwork(url:artist:track:))
            }
        }
        
        DispatchQueue.global().async(execute: workItem!)
        
    }
    
    func setArtwork(url: URL?, artist: String?, track: String?) {
        
        DispatchQueue.main.async {
            if (url != nil) {
                self.artworkImageView.downloaded(from: url!)
            }
        
            self.artistLabel.text = artist
            self.songLabel.text = track
        }
        
        
    }
    
    @objc func handleThreeFingerTap(sender: UITapGestureRecognizer) {
//        player?.reset(stations: stations!)
//        
//        let touchPoint = sender.location(in: self.view)
//        
//        let selectedProgram = stationButtons?.first(where: {$0.globalFrame!.contains(touchPoint)})
//
//        player?.play(program: selectedProgram!.tag)
//        setNowPlayingIndicator(button: selectedProgram!)
    }
    
    func initProgramButtons(buttons: [UIButton], stations: [RadioStation]) {
        
        for (index, button) in buttons.enumerated() {
            
            let programImage = UIImage(named: stations[index].imageAsset)?.resized(withPercentage: 0.85)
            
            button.setImage(programImage, for: .normal)
            button.backgroundColor = hexStringToUIColor(hex: stations[index].tileColor)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.white, for: .focused)
            button.setTitleColor(UIColor.white, for: .selected)
            button.imageView?.contentMode = .scaleAspectFit
            
        }
        
    }
    @IBAction func resetTapped(_ sender: Any) {
        player?.reset(stations: stations!)
    }
    
    var prev:CGFloat = 0.0
    @objc func panDetected(sender : UIPanGestureRecognizer) {
        
        let touchPoint = sender.location(in: self.view)
        
//        let selectedProgram = stationButtons?.first(where: {$0.globalFrame!.contains(touchPoint)})
//
//        player?.play(program: selectedProgram!.tag)
//        setNowPlayingIndicator(button: selectedProgram!)
               
        let vol = AVAudioSession.sharedInstance().outputVolume

        if (touchPoint.x < (prev - 10)) {
            if let view = volumeView.subviews.first as? UISlider { view.value = vol - 0.05 }
            prev = touchPoint.x
        } else if (touchPoint.x > (prev + 10)) {
            if let view = volumeView.subviews.first as? UISlider { view.value = vol + 0.05}
            prev = touchPoint.x
        }
        
        
    }
    
    
    @IBAction func programTouched(_ sender: UIButton) {
        
        self.currentStation = self.stations![sender.tag]
        self.player?.play(program: sender.tag)
        self.setNowPlayingIndicator(button: sender)
        
        tick()
    }
    
    func setNowPlayingIndicator(button: UIButton) {
        stationButtons?.forEach {$0.titleLabel?.text = ""}
        button.titleLabel?.text = "·"
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

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension UIView{
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}



