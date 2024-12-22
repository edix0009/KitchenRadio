import Foundation

struct KRTrack: Comparable {

    var raw: String
    var artist: String
    var name: String

    init(artist: String, name: String, raw: String) {
        self.artist = artist
        self.name = name
        self.raw = raw
    }
    
    static func == (lhs: KRTrack, rhs: KRTrack) -> Bool {
        return (lhs.name == rhs.name && lhs.artist == lhs.artist)
    }
    
    static func < (lhs: KRTrack, rhs: KRTrack) -> Bool {
        return true
    }
    
}
