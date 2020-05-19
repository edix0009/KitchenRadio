import UIKit
import AVKit
import MediaPlayer
import SwiftSoup
import DynamicBlurView

class ViewController: UIViewController {

    var slideGesture = UIPanGestureRecognizer()
    
    // Main button collection
    @IBOutlet weak var buttonCollaction: UIStackView!
    @IBOutlet var container: UIView!
    
    let volumeView = MPVolumeView()
    var player: RadioPlayer?
    var stationButtons: [UIButton]?
    var stations: [RadioStation]?
    var currentStation: Int?
    var timer = Timer()

    
    var workItem: DispatchWorkItem?
    
    // Control panel
    var currentStation: RadioStation?
    var lastReset: Date?
    
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
        print("stated :)")
        stations = loadStationsFromJSON(from: "stations")
        currentStation = stations?.first
        
        stationButtons = getSubviewsOf(view: buttonCollaction).filter{$0 is UIButton}
        initProgramButtons(buttons: stationButtons!, stations: stations!)
        
        player = RadioPlayer(stations: stations!)
        
        controlStackView.addBackground()
        controlStackView.addLine()
        //controlStackView.addBackground(color: hexStringToUIColor(hex: "#1B1B1B"))
        
        dateFormatter.dateFormat = "HH:mm"
        clock = Timer.scheduledTimer(timeInterval: 12.0, target: self, selector:#selector(self.tick) , userInfo: nil, repeats: true)
        tick()

        slideGesture = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
        slideGesture.maximumNumberOfTouches = 1
        container.addGestureRecognizer(slideGesture)
        
        
        // Three finger tap gesture to reset stations
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap))
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
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            DispatchQueue.main.async() {
                self.artworkImageView.image = UIImage(data: data)
                self.controlStackView.setBackground(image:  UIImage(data: data)!)
            }
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
        player?.play(program: sender.tag)
        setNowPlayingIndicator(button: sender)
    }
    
    
    func setNowPlayingIndicator(button: UIButton) {
        button.titleLabel?.text = "·"
        stationButtons?.forEach {$0.titleLabel?.text = ""}
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

extension UIStackView {

    func addLine() {
        let lineView = UIView()
        
        let lineHeight: CGFloat = 2.0
        lineView.frame = CGRect(x: 0, y: frame.height-lineHeight, width: frame.width, height: lineHeight)
        
        lineView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lineView.backgroundColor = .white
        lineView.alpha = 0.1
        
        addSubview(lineView)
    }
    
    func addBackground() {
        let subView = UIImageView(frame: bounds)
        subView.image = UIImage(named: "download-1")
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let blurView = DynamicBlurView(frame: bounds)
        blurView.trackingMode = .common
        blurView.blurRadius = 50
        blurView.iterations = 9
        blurView.blendMode = .multiply
        blurView.blendColor = UIColor.black.withAlphaComponent(0.45)

        
        subView.addSubview(blurView)
        self.insertSubview(subView, at: 0)
        
    }
    
    func setBackground(image: UIImage) {
        let imageview = self.subviews.first{$0 is UIImageView} as! UIImageView
        imageview.image = image.withSaturationAdjustment(byVal: 2.0)
    }
}

extension UIImage {
    
    func withSaturationAdjustment(byVal: CGFloat) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        guard let filter = CIFilter(name: "CIColorControls") else { return self }
        filter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        filter.setValue(byVal, forKey: kCIInputSaturationKey)
        guard let result = filter.value(forKey: kCIOutputImageKey) as? CIImage else { return self }
        guard let newCgImage = CIContext(options: nil).createCGImage(result, from: result.extent) else { return self }
        return UIImage(cgImage: newCgImage, scale: UIScreen.main.scale, orientation: imageOrientation)
    }
    
}

extension UIView{
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}



