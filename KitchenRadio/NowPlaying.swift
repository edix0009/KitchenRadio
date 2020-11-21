import Foundation
import SwiftSoup

class NowPlaying {

    static func extractTrackInfo(rawTrack: String) -> Track {
        
        let components = rawTrack.components(separatedBy: ["-", "|"])
        
        if components.count >= 2 {
            let artist_t = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let name_t = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return Track(artist: artist_t, name: name_t)
        }
        
        return Track(artist: "Unknown", name: "Unknow")
    }
        

    static func parsePlaylistHTML(content: String) -> String {

        do {
            let doc = try SwiftSoup.parse(content)
            if let active = (try? doc.select("table.tablelist-schedule tr:first-child td").last()) {
                return try active.text()
            } else {
                return "unknown"
            }
        } catch let error {
           print(error.localizedDescription)
       }

        return "unknown"
    }
    
    static func printTrack(track: Track) {
        print("Artist: \(track.artist)")
        print("Track: \(track.name)")
    }
    
    static func GetCurrentTrack(url: String, success: @escaping ((_ track: Track) -> Void)) {
        let session = URLSession.shared
        let url = URL(string: url)!
        let task = session.dataTask(with: url) { data, response, error in
            guard let loadedData = data else { return }
            
            let content = String(data: loadedData, encoding: .utf8)
            let rawTrackInfo = parsePlaylistHTML(content: content!)
            let track = extractTrackInfo(rawTrack: rawTrackInfo)
            
            success(track)
            
        }
        task.resume()
    }
    
}
