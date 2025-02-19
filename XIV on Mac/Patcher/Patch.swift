//
//  Patch.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 25.02.22.
//

import AppKit
import XIVLauncher

public struct Patch: Codable {
    let version, hashType: String
    private let _url: String
    let hashBlockSize: Int
    let hashes: [String]?
    let length: Int64

    enum CodingKeys: String, CodingKey {
        case version = "VersionId"
        case hashType = "HashType"
        case _url = "Url"
        case hashBlockSize = "HashBlockSize"
        case hashes = "Hashes"
        case length = "Length"
    }
    
    static let dir = Util.applicationSupport.appendingPathComponent("patch")

    var url: URL {
        URL(string: _url)!
    }
    
    var name: String {
        [repo.rawValue, String(url.lastPathComponent.dropLast(6))].joined(separator: "/")
    }
    var path: String {
        url.pathComponents.dropFirst().joined(separator: "/")
    }
    var repo: FFXIVRepo {
        FFXIVRepo(rawValue: url.pathComponents[2]) ??
        (url.pathComponents[1] == "boot" ? .boot : .game)
    }
    
    static func totalLength(_ patches: [Patch]) -> Int64 {
        patches.map{$0.length}.reduce(0, +)
    }
    
    static func totalLength(_ patches: ArraySlice<Patch>) -> Int64 {
        totalLength(Array(patches))
    }
    
    static private let keepKey = "KeepPatches"
    static var keep: Bool {
        get {
            UserDefaults.standard.bool(forKey: keepKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keepKey)
        }
    }
    
    static var userAgent: String {
        String(cString: getPatcherUserAgent())
    }
    
    static var bootPatches: [Patch] {
        get throws {
            let patchesJSON = String(cString: getBootPatches())
            do {
                return try JSONDecoder().decode([Patch].self, from: patchesJSON.data(using: .utf8)!)
            }
            catch {
                throw XLError.runtimeError(patchesJSON)
            }
        }
    }
    
    func install() {
        let patchPath = Patch.dir.appendingPathComponent(self.path).path
        let valid = checkPatchValidity(patchPath, Int(length), hashBlockSize, hashType, hashes?.joined(separator: ",") ?? "")
        guard valid else {
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .critical
                alert.messageText = "Patch Installer Error"
                alert.informativeText = "Patch Verification failed"
                alert.runModal()
                try! FileManager.default.removeItem(atPath: patchPath)
                Util.quit()
            }
            return
        }
        var repo = self.repo
        let res = String(cString: installPatch(patchPath, repo.patchURL.path))
        if res == "OK" {
            repo.ver = self.version
            Log.information("Updated ver to \(repo.ver)")
        }
        else {
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .critical
                alert.messageText = "Patch Installer Error"
                alert.informativeText = res
                alert.runModal()
                Util.quit()
            }
        }
        if !Patch.keep {
            try? FileManager.default.removeItem(atPath: patchPath)
        }
    }
}
