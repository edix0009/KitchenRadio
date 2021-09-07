//
//  SpotifyAuth.swift
//  KitchenRadio
//
//  Created by Edi Begovic on 29/11/2020.
//  Copyright © 2020 Edi Begovic. All rights reserved.
//

import Foundation
import Spartan

struct TokenEndpointResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }

    let accessToken: String
    let expiresIn: Double
    let refreshToken: String?
}


class SpotifyAuth {
        
    static let clientID = "741393d71110475c9dfe011b6966f50f"
    static let clientSecret = "486811a667fe48faa352dac931c66704"
    static let refreshToken = "AQBPdulHHrFF0pZDCX67qReZ46xV65UGRmN6PST4fJMDzeMyNyDTIoWktLkhEEVJwNSh4rpdTTCooYFDrwMrh-etwx8e9W0tFyx9m0vg6izwcIghaMRkjGc6v0IBa2OJuR8"
    
    static let requestBody = "grant_type=refresh_token&refresh_token=\(refreshToken)"
    static let apiTokenEndpointURL = "https://accounts.spotify.com/api/token"
    
    
    static func authRequest(completion: @escaping (TokenEndpointResponse?, Error?) -> Void) {
        
        guard let authString = "\(clientID):\(clientSecret)"
            .data(using: .ascii)?.base64EncodedString(options: .endLineWithLineFeed) else {
            print("Spotify API failed 928")
            return
        }
        let endpoint = URL(string: apiTokenEndpointURL)!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        urlRequest.httpMethod = "POST"

        let authHeaderValue = "Basic \(authString)"
        urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = requestBody.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: urlRequest,
                                              completionHandler: { (data, _, error) in
            
                                                print(String(decoding: data!, as: UTF8.self))
            if let data = data,
                let authResponse = try? JSONDecoder().decode(TokenEndpointResponse.self, from: data), error == nil {
                DispatchQueue.main.async {
                    completion(authResponse, error)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        })
        task.resume()
    }
    
//    static func addTrackToPlaylist(query: String) {
//
//        authRequest() {tokenResponse,_ in
//
//            Spartan.authorizationToken = tokenResponse?.accessToken
//            Spartan.search(query: query, type: .track, success: { (pagingObject: PagingObject<Track>) in
//                guard let trackURI = (pagingObject.items.first?.uri) else { return }
//
//                Spartan.addTracksToPlaylist(userId: "nnnnnnko", playlistId: "62TNaAbFKZuQ3Z68qwSDhc", trackUris: [trackURI], success: { (snapshot) in
//                    print("Added!")
//
//                }, failure: { (error) in
//                    print(error)
//                })
//
//            }, failure: { (error) in
//            print(error)
//            })
//
//        }
//    }
    
    
    static func addTrackToPlaylist(query: String, success: @escaping ((_) -> String)) {
        
        authRequest() {tokenResponse,_ in
            
            Spartan.authorizationToken = tokenResponse?.accessToken
            Spartan.search(query: query, type: .track, success: { (pagingObject: PagingObject<Track>) in
                guard let trackURI = (pagingObject.items.first?.uri) else { return }
                
                Spartan.addTracksToPlaylist(userId: "nnnnnnko", playlistId: "62TNaAbFKZuQ3Z68qwSDhc", trackUris: [trackURI], success: { (snapshot) in
                    print("Added!")
                    success("Get song")
                    
                }, failure: { (error) in
                    print(error)
                    success(":(")
                })
                
            }, failure: { (error) in
            print(error)
            })
            
        }
    }
    
}
