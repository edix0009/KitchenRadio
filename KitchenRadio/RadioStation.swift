import UIKit

struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var playlistURL: String
    var imageAsset: String
    var tileColor: String
    
    init(name: String, streamURL: String, playlistURL: String, imageAsset: String, tileColor: String) {
        self.name = name
        self.streamURL = streamURL
        self.playlistURL = playlistURL
        self.imageAsset = imageAsset
        self.tileColor = tileColor
    }
    
}
