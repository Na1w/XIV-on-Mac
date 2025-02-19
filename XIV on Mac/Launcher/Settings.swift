//
//  Settings.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 19.02.22.
//

import Foundation
import XIVLauncher

public struct Settings {
    private static let storage = UserDefaults.standard
    
    static func syncToXL() {
        loadConfig(acceptLanguage, gamePath.path, gameConfigPath.path, language.rawValue, true, true, freeTrial, platform.rawValue, Patch.dir.path, 0, 0, true, dalamudEnabled ? 1 : 2, Int32(Settings.injectionDelay * 1000))
    }
    
    private static let platformKey = "Platform"
    static var platform: FFXIVPlatform {
        get {
            FFXIVPlatform(rawValue: Util.getSetting(settingKey: platformKey, defaultValue: FFXIVPlatform.mac.rawValue)) ?? .mac
        }
        set {
            storage.set(newValue.rawValue, forKey: platformKey)
            syncToXL()
            Wine.addReg(key: "HKEY_CURRENT_USER\\Software\\Wine", value: "HideWineExports", data: newValue == .mac ? "0" : "1")
        }
    }
    
    private static let gamePathKey = "GamePath"
    static let defaultGameLoc = Util.applicationSupport.appendingPathComponent("ffxiv")
    static var gamePath: URL {
        get {
            URL(fileURLWithPath: Util.getSetting(settingKey: gamePathKey, defaultValue: defaultGameLoc.path))
        }
        set {
            storage.set(newValue.path, forKey: gamePathKey)
            syncToXL()
        }
    }
    
    static func setDefaultGamepath() {
        storage.removeObject(forKey: gamePathKey)
        syncToXL()
    }
    
    private static let gameConfigPathKey = "GameConfigPath"
    static let defaultGameConfigLoc = Util.applicationSupport.appendingPathComponent("ffxivConfig")
    static var gameConfigPath: URL {
        get {
            URL(fileURLWithPath: Util.getSetting(settingKey: gameConfigPathKey, defaultValue: defaultGameConfigLoc.path))
        }
        set {
            storage.set(newValue.path, forKey: gameConfigPathKey)
            syncToXL()
        }
    }
    
    private static let usernameKey = "Username"
    private static var credentialsCache: LoginCredentials?
    static var credentials: LoginCredentials? {
        get {
            if let creds = credentialsCache {
                return creds
            }
            if let storedUsername = storage.string(forKey: usernameKey) {
                return LoginCredentials.storedLogin(username: storedUsername)
            }
            return nil
        }
        set {
            if let creds = newValue {
                storage.set(creds.username, forKey: usernameKey)
                creds.saveLogin()
                credentialsCache = creds
            }
        }
    }
    
    private static let freeTrialKey = "FreeTrial"
    static var freeTrial: Bool {
        get {
            storage.bool(forKey: freeTrialKey)
        }
        set {
            storage.set(newValue, forKey: freeTrialKey)
            syncToXL()
        }
    }
    
    private static let usesOneTimePasswordKey = "UsesOneTimePassword"
    static var usesOneTimePassword: Bool {
        get {
            storage.bool(forKey: usesOneTimePasswordKey)
        }
        set {
            storage.set(newValue, forKey: usesOneTimePasswordKey)
        }
    }
    
    private static let autoLoginKey = "AutoLogin"
    static var autoLogin: Bool {
        get {
            storage.bool(forKey: autoLoginKey)
        }
        set {
            storage.set(newValue, forKey: autoLoginKey)
        }
    }
    
    private static let acceptLanguageKey = "AcceptLanguage"
    static var acceptLanguage: String {
        guard let storedAcceptLanguage = storage.object(forKey: acceptLanguageKey) else {
            let seed = Int32.random(in: 0..<420)
            let newAcceptLaungage = String(cString: generateAcceptLanguage(seed)!)
            storage.set(newAcceptLaungage, forKey: acceptLanguageKey)
            return newAcceptLaungage
        }
        return storedAcceptLanguage as! String
    }
    
    private static let languageKey = "Language"
    static var language: FFXIVLanguage {
        get {
            let guess = FFXIVLanguage.guessFromLocale()
            let stored = UInt8(Util.getSetting(settingKey: languageKey, defaultValue: guess.rawValue))
            return FFXIVLanguage(rawValue: stored) ?? guess
        }
        set {
            storage.set(newValue.rawValue, forKey: languageKey)
            syncToXL()
        }
    }
    
    private static let dalamudSettingsKey = "DalamudEnabled"
    static var dalamudEnabled: Bool {
        get {
            storage.bool(forKey: dalamudSettingsKey)
        }
        set {
            storage.set(newValue, forKey: dalamudSettingsKey)
            syncToXL()
        }
    }
    
    public static let defaultInjectionDelay = 4.0
    private static let injectionSettingKey = "InjectionDelaySetting"
    static var injectionDelay: Double {
        get {
            return Util.getSetting(settingKey: injectionSettingKey, defaultValue: defaultInjectionDelay)
        }
        set {
            storage.set(newValue, forKey: injectionSettingKey)
            syncToXL()
        }
    }
}
