import Foundation
import UIKit
import AVKit

class RadioPlayer  {
    
    var streams: [AVPlayer]?
    var stations: [RadioStation]?
    
    init(stations: [RadioStation]) {

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlay(_:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlay(_:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        
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
        
        streams = stations.map{AVPlayer(url: URL.init(string: $0.streamURL)!)}
        streams?.forEach{$0.play(); $0.isMuted = true}
    
    }

    @objc func playerItemFailedToPlay(_ notification: Notification) {
//        let error = notification.userInfo?.first(where: { $0.value is Error }) as? Error
        
//        let player = (notification.object as! AVPlayer)
//        player.pause()
    }

    
}

extension AVPlayer {
    var isPlaying: Bool? {
        return rate != 0
    }
}
