import Foundation
import UIKit

class NowPlaying {

    static func extractTrackInfo(rawTrack: String) -> KRTrack {
        
        let replaced = rawTrack.replacingOccurrences(of: " / ", with: " - ")
        let components = replaced.components(separatedBy: " - ")
        
        if components.count >= 2 {
            let artist_t = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let name_t = components[1].split(separator: "|").first!.trimmingCharacters(in: .whitespacesAndNewlines)
            return KRTrack(artist: artist_t, name: name_t, raw: rawTrack)
        }
        
        return KRTrack(artist: "Unknown", name: "Unknown", raw: "")
    }
    
    struct P3Track: Decodable {
        
        struct TrackItem: Decodable {
            let title: String?
        }
        
        let track: TrackItem?
        
    }
    
    struct S21Track: Codable {
      let a: String?
      let t: String?
      
        enum CodingKeys: String, CodingKey {
          case a = "a"
          case t = "t"
      }
        
    }
    
    struct ERFTTrack: Decodable {
        let artist: String
        let title: String
        
        var currentTrack: String {
            return "\(title) - \(artist)"
        }
        
        private enum CodingKeys: String, CodingKey {
            case artist, title
        }
    }
        

    static func parseJSON(content: String) -> String {
        let jsonData = content.data(using: .utf8)!
        print(content)
        // P3 Din Gata
        if (content.contains("\"track\":")) {
            let p3track: P3Track? = try? JSONDecoder().decode(P3Track.self, from: jsonData)
            return p3track?.track?.title ?? "P3 - Din Gata"
        }
        // OlineRadioBox
        else if (content.contains("\"stationId\":")) {
            let orbTrack: ORBTrack? = try? JSONDecoder().decode(ORBTrack.self, from: jsonData)
            return orbTrack?.title ?? "Unknown"
        }
        // Studio21
        else if (content.contains("\"t\":")) {
            let s21track: S21Track? = try? JSONDecoder().decode(S21Track.self, from: jsonData)
            return (s21track?.a ?? " ") + " - " + (s21track?.t ?? " ")
        }
        // RadioERFT
        else if (content.contains("\"station_id\":")) {
            let erftTrack: [ERFTTrack]? = try? JSONDecoder().decode([ERFTTrack].self, from: jsonData)
            return erftTrack?.first?.currentTrack ?? "Unknown"
        }
        return "Unknown"
    }
    
    static func printTrack(track: KRTrack) {
        print("Artist: \(track.artist)")
        print("Track: \(track.name)")
    }
    
    static func GetCurrentTrack(url: String, success: @escaping ((_ track: KRTrack) -> Void)) {
        
        let session = URLSession.shared
        let url = URL(string: url)!
        let task = session.dataTask(with: url) { data, response, error in
            guard let loadedData = data else { return }
            
            let content = String(data: loadedData, encoding: .utf8)
            let rawTrackInfo = parseJSON(content: content ?? "")
            let track = extractTrackInfo(rawTrack: rawTrackInfo)
            
            success(track)
            
        }
        task.resume()
    }
    
    static func GetArtwork(query: String, success: @escaping ((_ image: UIImage) -> Void)) {
        let query = query == "Unknown Unknown" ? "Unknown Pleasures Joy" : query
        
        ItunesAPI.getArtwork(for: query, size: 900) { url in
            if (url != nil) {
                let data = try? Data(contentsOf: url!)
                success(UIImage(data: data!) ?? UIImage(named: "placeholderAlbumCover")!)
            } else {
                success(UIImage(named: "placeholderAlbumCover")!)
            }
        }
    }
    
}
