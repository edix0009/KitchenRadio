import Foundation
import UIKit
import AVKit

class RadioPlayer  {
    
    var streams: [AVPlayer]?
    var stations: [RadioStation]?
    
    init(stations: [RadioStation]) {
        
        self.stations = stations
        reset(stations: stations)
    }
    
    func play(program: Int) {
        
        if (streams?.first(where: {$0.isMuted == false}) == streams?[program]) { return }
        streams?.forEach{ $0.isMuted = true }
        streams?[program].isMuted = false
        
    }
    
    func reset(stations: [RadioStation]) {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        
        streams = stations.map { AVPlayer(url: URL.init(string: $0.streamURL)!) }
        streams?.forEach{ $0.play(); $0.isMuted = true; }
        
    }
    
}

extension AVPlayer {
    var isPlaying: Bool? {
        return rate != 0
    }
}
