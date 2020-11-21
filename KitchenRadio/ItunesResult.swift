// MARK: - Result
struct Result: Codable {
    let kind: String
    let artistID, trackID: Int
    let artistName, trackName, trackCensoredName: String
    let artistViewURL, trackViewURL: String
    let previewURL: String
    let artworkUrl30, artworkUrl60, artworkUrl100: String
}
