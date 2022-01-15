import Foundation

internal struct ItunesAPI {
    
    static func getArtwork(for metadata: String, size: Int, completionHandler: @escaping (_ artworkURL: URL?) -> ()) {
        
        let cleanMetadata = cleanRawMetadataIfNeeded(metadata)
        print(cleanMetadata)
        
        guard !cleanMetadata.isEmpty, cleanMetadata !=  " - ", let url = getURL(with: cleanMetadata) else {
            completionHandler(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error == nil, let data = data else {
                completionHandler(nil)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let parsedResult = json as? [String: Any],
                let results = parsedResult[Keys.results] as? Array<[String: Any]>,
                let result = results.first,
                var artwork = result[Keys.artwork] as? String else {
                    completionHandler(nil)
                    return
            }
            
            if size != 100, size > 0 {
                artwork = artwork.replacingOccurrences(of: "100x100", with: "\(size)x\(size)")
            }
            
            let artworkURL = URL(string: artwork)
            completionHandler(artworkURL)
        }).resume()
    }
    
    private static func getURL(with term: String) -> URL? {
        var components = URLComponents()
        components.scheme = Domain.scheme
        components.host = Domain.host
        components.path = Domain.path
        components.queryItems = [URLQueryItem]()
        components.queryItems?.append(URLQueryItem(name: Keys.term, value: term))
        components.queryItems?.append(URLQueryItem(name: Keys.entity, value: Values.entity))
        return components.url
    }
    
    static func removeSpecials(artistName: String) -> String {
        
        var x = artistName
        let skipPatterns = [", ", ";", "& ", "(feat. ", "feat. ",
                            "ft. ", "Ft. ", " ft "]
        
        skipPatterns.forEach { pattern in
            x.removingRegexMatches(pattern: pattern, replaceWith: " ")
        }
        
        return x
    }
    
    public static func cleanRawMetadataIfNeeded(_ rawValue: String) -> String {
        
        let pattern = #"(\(.*?\)\w*)|(\[.*?\]\w*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return rawValue }
        
        let rawCleaned = NSMutableString(string: rawValue)
        regex.replaceMatches(in: rawCleaned , options: .reportProgress, range: NSRange(location: 0, length: rawCleaned.length), withTemplate: "")
        
        var cleaned = rawCleaned as String
        cleaned = removeSpecials(artistName: cleaned)
        
        return cleaned
    }
    
    private struct Domain {
        static let scheme = "https"
        static let host = "itunes.apple.com"
        static let path = "/search"
    }
    
    private struct Keys {
        static let term = "term"
        static let entity = "entity"
        
        static let results = "results"
        static let artwork = "artworkUrl100"
    }
    
    private struct Values {
        static let entity = "song"
    }
}
