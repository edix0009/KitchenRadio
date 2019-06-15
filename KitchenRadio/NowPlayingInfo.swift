//
//  NowPlayingInfo.swift
//  KitchenRadio
//
//  Created by Edi Begovic on 15/06/2019.
//  Copyright © 2019 Edi Begovic. All rights reserved.
//

import Foundation
import UIKit
import SwiftSoup

class NowPlayingInfo {

    static func getTrackInfo(url: String) -> String? {
        
        if let url = URL(string: url) {
            do {
                let contents = try String(contentsOf: url)
                
                let latestRow = try parse(contents)
                    .select("tbody").first()?
                    .select("tr").first()

                if let row = try latestRow?.select("a").first()?.text() {
                    return row
                    
                } else if let row = try latestRow?.select("td").last()?.text() {
                    return row
                }
                
            } catch {}
        }
        return nil
        
    }
    
}





