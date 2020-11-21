import UIKit
import AVKit
import MediaPlayer
import SwiftSoup


class ViewController: UIViewController {

    var slideGesture = UIPanGestureRecognizer()
    
    
    @IBOutlet weak var bg: UIImageView!
    @IBOutlet weak var buttonCollaction: UIStackView!
    @IBOutlet var container: UIView!
    
    let volumeView = MPVolumeView()
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    var currentStation: Int?
    var timer = Timer()
    var nowPLaying = NowPlaying()

    @IBOutlet weak var nowPlayingView: UIView!
    @IBOutlet weak var artworkView: UIView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var getSongButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("stated :)")
        stations = loadStationsFromJSON(from: "stations")
        
        stationButtons = getSubviewsOf(view: self.container).filter{$0.tag >= 0}
        initProgramButtons(buttons: stationButtons!, stations: stations!)
        
        player = RadioPlayer(stations: stations!)
        

        slideGesture = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
        slideGesture.maximumNumberOfTouches = 1
        container.addGestureRecognizer(slideGesture)
        
        
        // Three finger tap gesture to reset stations
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap))
        gesture.numberOfTapsRequired = 3
        container.addGestureRecognizer(gesture)
     
        scheduledRadioReset()
        
        // init getSongButton
        getSongButton.setImage(UIImage(named: "note")?.resized(withPercentage: 0.58), for: .normal)
        getSongButton.layer.cornerRadius = 37
        getSongButton.layer.shadowColor = UIColor.black.cgColor
        getSongButton.layer.shadowOffset = CGSize(width: 0.0, height: 6.0)
        getSongButton.layer.shadowRadius = 15.0
        getSongButton.layer.shadowOpacity = 0.25
        
        nowPlayingView.layer.cornerRadius = 6
        nowPlayingView.layer.shadowColor = UIColor.black.cgColor
        nowPlayingView.layer.shadowOffset = CGSize(width: 0.0, height: 6.0)
        nowPlayingView.layer.shadowRadius = 15.0
        nowPlayingView.layer.shadowOpacity = 0.37
        
        artworkView.setBackgroundImage(img: UIImage(named: "currents")!)
        artworkView.layer.cornerRadius = 3.0
        artworkView.layer.shadowColor = UIColor.black.cgColor
        artworkView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        artworkView.layer.shadowRadius = 4.0
        artworkView.layer.shadowOpacity = 0.32
        
        nowPlayingView.isHidden = true
    }
    

    
    func scheduledRadioReset(){
        timer = Timer.scheduledTimer(timeInterval: 18000, target: self, selector: #selector(handleThreeFingerTap), userInfo: nil, repeats: true)
    }
    
    @objc func hideNowPlayingView() {
        self.toggleNowPlayingView(show: false)
    }

    @IBAction func getSong(_ sender: Any) {
        
        if (!self.nowPlayingView.isHidden) {
            self.toggleNowPlayingView(show: false)
            return
        }
        
        getSongButton.loadingIndicator(true)
        
        let playlistURL = stations![currentStation ?? 0].playlistURL
        NowPlaying.GetCurrentTrack(url: playlistURL) { (track) in
            DispatchQueue.main.async {
                self.artistLabel.text = track.artist
                self.trackLabel.text = track.name
            }
            
            let itunesQuery = track.name + " " + track.artist
            ItunesAPI.getArtwork(for: itunesQuery, size: 900) { (url) in
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    DispatchQueue.main.async { [self] in
                        NSObject.cancelPreviousPerformRequests(withTarget: self)
                        self.artworkView.setBackgroundImage(img: UIImage(data: data!)!)
                        getSongButton.loadingIndicator(false)
                        self.toggleNowPlayingView(show: self.nowPlayingView.isHidden)
                        perform(#selector(hideNowPlayingView), with: nil, afterDelay: 15)
                    }
                }
                
            }
            
        }
    }
    
    func toggleNowPlayingView(show: Bool) {
        UIView.transition(with: nowPlayingView.superview!, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.nowPlayingView.isHidden = !show
                      })
    }
    
    func parsePlaylistHTML(content: String) {

       do {

           let doc = try SwiftSoup.parse(content)
           let link: Element = try doc.getElementsByClass("active").first()!
           let linkHref = try link.select("b")

            print(try linkHref.text())
       } catch let error {
           print(error.localizedDescription)
       }
    
        DispatchQueue.main.async {
            // DO UI STUFF HERE
        }
    }
    
    func getPlaylistHTML(url: String) {
        
        let session = URLSession.shared
        let url = URL(string: url)!
        let task = session.dataTask(with: url) { data, response, error in
            guard let loadedData = data else { return }
            let content = String(data: loadedData, encoding: .utf8)
            self.parsePlaylistHTML(content: content!)
            
        }
        task.resume()
        
    }
    
    @objc func handleThreeFingerTap() {
        player?.reset(stations: stations!)
        player?.play(program: currentStation ?? 1)
    }
    
    func initProgramButtons(buttons: [UIButton], stations: [RadioStation]) {
        
        for (index, button) in buttons.enumerated() {
            let buttonWidth = button.frame.size.width
            let programImage = UIImage(named: stations[index].imageAsset)?.resized(withPercentage: buttonWidth/360)
            
            button.setImage(programImage, for: .normal)
            button.backgroundColor = hexStringToUIColor(hex: stations[index].tileColor)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(UIColor.white, for: .focused)
            button.setTitleColor(UIColor.white, for: .selected)
            button.imageView?.contentMode = .scaleAspectFit
        }
        
    }

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
    
    
    @IBAction func programTouched(_ sender: UIButton) {
        print(1)
        player?.play(program: sender.tag)
        currentStation = sender.tag
        setNowPlayingIndicator(button: sender)
        
        stationButtons?.forEach { setButtonShadow(button: $0, opacity: 0.13, blur: 10) }
        setButtonShadow(button: sender)
        
        toggleNowPlayingView(show: false)
    }
    
    
    
    func setButtonShadow(button: UIButton, opacity: Float = 0.4, blur: CGFloat = 20.0) {
        
        UIView.transition(with: button,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: {
                            button.layer.shadowColor = UIColor.black.cgColor
                            button.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
                            button.layer.shadowRadius = blur
                            button.layer.shadowOpacity = opacity
                          },
                          completion: nil)
    }
    
    @IBOutlet weak var bgView: UIView!
    func setNowPlayingIndicator(button: UIButton) {
        self.bgView.backgroundColor = button.backgroundColor!
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

extension UIView{
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}

extension UIView{

    func setBackgroundImage(img: UIImage){

        UIGraphicsBeginImageContext(self.frame.size)
        img.draw(in: self.bounds)
        let patternImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.backgroundColor = UIColor(patternImage: patternImage)
    }
}
