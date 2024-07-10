import Foundation

public struct Update {
    public private(set) var text = "Hello, World!"
    private var updateInfo: UpdateInfo?
    public private(set) var showAlert = false
    public private(set) var mandatoryUpdate = false
    public private(set) var latestVersion = ""
    var currentVersion: String = Bundle.main.currentVersion

    public init() {}

    public mutating func updateVersionInfo(currentVersion: String, latestVersion: String, mandatoryUpdate: Bool) {
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.mandatoryUpdate = mandatoryUpdate
        self.showAlert = latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    public mutating func handleUpdate() {
        currentVersion = latestVersion
        showAlert = false
        print("Version updated to \(latestVersion)")
    }
}

public class UpdateManager {
    public static let shared = UpdateManager()

    private init() {}

    public func checkForUpdates(completion: @escaping (Update) -> Void) {
        guard let url = URL(string: "https://librarybackend-vtqc.onrender.com/checkForUpdates") else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                let updateInfo = try JSONDecoder().decode(UpdateInfo.self, from: data)
                var update = Update()
                if let latestVersionInfo = updateInfo.versions.sorted(by: { $0.version > $1.version }).first {
                    update.updateVersionInfo(currentVersion: update.currentVersion, latestVersion: latestVersionInfo.version, mandatoryUpdate: latestVersionInfo.mandatory)
                }
                DispatchQueue.main.async {
                    completion(update)
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
}

public struct VersionInfo: Codable, Identifiable {
    public var id: String
    public var version: String
    public var mandatory: Bool

    public enum CodingKeys: String, CodingKey {
        case id = "_id"
        case version
        case mandatory
    }

    public init(id: String, version: String, mandatory: Bool) {
        self.id = id
        self.version = version
        self.mandatory = mandatory
    }
}

public struct UpdateInfo: Codable {
    public var versions: [VersionInfo]

    public init(versions: [VersionInfo]) {
        self.versions = versions
    }
}

public extension Bundle {
    var currentVersion: String {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}
