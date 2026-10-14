import CryptoKit
import Foundation
import UIKit

/// Grafika naglowka eventu (opcjonalna, z CMS), trzymana lokalnie jak w Androidzie
/// (data/HeaderImages.kt): pobierana przy odswiezeniu bundla, ekran czyta ja z dysku.
/// Plik: Documents/headers/<eventId>_<sha256(url)>.img. Nowy URL = nowy plik, stare kasujemy.
enum HeaderImages {
    private static let maxBytes = 5 * 1024 * 1024
    /// Zdekodowane obrazy (widok eventu przelicza body czesto, nie dekodujemy za kazdym razem).
    private static let cache = NSCache<NSString, UIImage>()

    private static var dir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("headers")
    }

    static func file(eventId: Int64, url: String) -> URL {
        let hash = SHA256.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16)
        return dir.appendingPathComponent("\(eventId)_\(hash).img")
    }

    /// Pobiera grafike, gdy jej brak; usuwa nieaktualne pliki eventu. Bledy sieci ignorowane.
    static func ensure(eventId: Int64, url: String?) async {
        let keep = url.map { file(eventId: eventId, url: $0) }
        removeFiles(eventId: eventId, except: keep)
        guard let url, let keep, url.hasPrefix("https://"), let remote = URL(string: url),
              !FileManager.default.fileExists(atPath: keep.path) else { return }
        guard let (data, resp) = try? await URLSession.shared.data(from: remote),
              let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
              data.count <= maxBytes, UIImage(data: data) != nil else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: keep, options: .atomic)
    }

    static func delete(eventId: Int64) { removeFiles(eventId: eventId, except: nil) }

    static func load(eventId: Int64, url: String?) -> UIImage? {
        guard let url else { return nil }
        let path = file(eventId: eventId, url: url).path
        if let hit = cache.object(forKey: path as NSString) { return hit }
        guard let img = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(img, forKey: path as NSString)
        return img
    }

    private static func removeFiles(eventId: Int64, except keep: URL?) {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: dir.path) else { return }
        for n in names where n.hasPrefix("\(eventId)_") && n != keep?.lastPathComponent {
            try? fm.removeItem(at: dir.appendingPathComponent(n))
        }
    }
}
