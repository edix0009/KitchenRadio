import Foundation
import UIKit
import AVKit

class RadioPlayer  {
    
    var streams: [AVPlayer]?
    var stations: [RadioStation]?
    var currentStation: Int = 0
    
    init(stations: [RadioStation]) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlay(_:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlay(_:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        
        self.stations = stations
        reset(stations: stations)
    }
    
    func play(program: Int) {
        
        if (streams?.first(where: { $0.isMuted == false }) == streams?[program]) { return }
        streams?.forEach{ $0.isMuted = true }
        streams?[program].isMuted = false
        currentStation = program
    }
    
    func reset(stations: [RadioStation]) {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        
        streams = stations.map{ AVPlayer(url: URL.init(string: $0.streamURL)!) }
        streams?.forEach{ $0.play(); $0.isMuted = true; }
        
    }
    
    @objc func playerItemFailedToPlay(_ notification: Notification) {
        
//        let currentStation = streams?
//            .enumerated()
//            .filter{ !$0.element.isMuted }
//            .first?
//            .offset

        DispatchQueue.main.asyncAfter(deadline: .now() + 61.0) {
            self.reset(stations: self.stations!)
            self.play(program: self.currentStation)
        }
        
    }

}

extension AVPlayer {
    var isPlaying: Bool? {
        return rate != 0
    }
}
