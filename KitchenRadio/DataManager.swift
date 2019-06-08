import UIKit

struct DataManager {
    
    static func getDataFromFileWithSuccess(file: String, success: (_ data: Data?) -> Void) {
        guard let filePathURL = Bundle.main.url(forResource: file, withExtension: "json") else {
            print("The local JSON file could not be found")
            success(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            success(data)
        } catch {
            fatalError()
        }
    }
    
}
