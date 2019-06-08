import UIKit
import AVKit
import MediaPlayer


class ViewController: UIViewController {

    var slideGesture = UIPanGestureRecognizer()
    
    
    @IBOutlet weak var buttonCollaction: UIStackView!
    @IBOutlet var container: UIView!
    
    let volumeView = MPVolumeView()
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stations = loadStationsFromJSON(from: "stations")
        
        stationButtons = getSubviewsOf(view: buttonCollaction).filter{$0 is UIButton}
            initProgramButtons(buttons: stationButtons!, stations: stations!)
        
        player = RadioPlayer(stations: stations!)
        

        slideGesture = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
        slideGesture.maximumNumberOfTouches = 1
        container.addGestureRecognizer(slideGesture)
        
        
        // Three finger tap gesture to reset stations
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap(sender:)))
        gesture.numberOfTapsRequired = 3
        container.addGestureRecognizer(gesture)
        
    }
    
    @objc func handleThreeFingerTap(sender: UITapGestureRecognizer) {
        player?.reset(stations: stations!)
        
        let touchPoint = sender.location(in: self.view)
        
        let selectedProgram = stationButtons?.first(where: {$0.globalFrame!.contains(touchPoint)})

        player?.play(program: selectedProgram!.tag)
        setNowPlayingIndicator(button: selectedProgram!)
    }
    
    func initProgramButtons(buttons: [UIButton], stations: [RadioStation]) {
        
        for (index, button) in buttons.enumerated() {
            
            let programImage = UIImage(named: stations[index].imageAsset)?.resized(withPercentage: 0.95)
            
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
        player?.play(program: sender.tag)
        setNowPlayingIndicator(button: sender)
    }
    
    func setNowPlayingIndicator(button: UIButton) {
        stationButtons?.forEach {$0.titleLabel?.text = ""}
        button.titleLabel?.text = "__"
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

extension UIView{
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}



