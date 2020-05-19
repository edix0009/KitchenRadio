//
//  FRadioAPI.swift
//  FRadioPlayer
//
//  Created by Fethi El Hassasna on 2017-11-25.
//  Copyright © 2017 Fethi El Hassasna (@fethica). All rights reserved.
//

import Foundation

// MARK: - iTunes API
internal struct FRadioAPI {
    
    // MARK: - Util methods
    
    static func getArtwork(for metadata: String, size: Int, completionHandler: @escaping (_ artworkURL: URL?, _ artist: String?, _ track: String?) -> ()) {
        print(metadata)
        guard !metadata.isEmpty, metadata !=  " - ", let url = getURL(with: metadata) else {
            return
        }
                
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error == nil, let data = data else {
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let parsedResult = json as? [String: Any],
                let results = parsedResult[Keys.results] as? Array<[String: Any]>,
                let result = results.first,
                var artwork = result[Keys.artwork] as? String,
                let artist = result["artistName"] as? String,
                let track = result["trackName"] as? String else { return }
            
            if size != 100, size > 0 {
                artwork = artwork.replacingOccurrences(of: "100x100", with: "\(size)x\(size)")
            }
            
            let artworkURL = URL(string: artwork)
            completionHandler(artworkURL, artist, track)
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
    
    // MARK: - Constants
    
    private struct Domain {
        static let scheme = "https"
        static let host = "itunes.apple.com"
        static let path = "/search"
    }
    
    private struct Keys {
        // Request
        static let term = "term"
        static let entity = "entity"
        
        // Response
        static let results = "results"
        static let artwork = "artworkUrl100"
    }
    
    private struct Values {
        static let entity = "song"
    }
}
