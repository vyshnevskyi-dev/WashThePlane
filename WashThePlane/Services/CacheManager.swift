//
//  CacheManager.swift
//  WashThePlane
//

import Foundation

final class CacheManager {
    static let shared = CacheManager()
    private init() {}

    private let defaults = UserDefaults.standard

    func saveTargetLink(_ link: String) { defaults.set(link, forKey: AppConfig.cachedLinkKey) }
    func getTargetLink() -> String? { defaults.string(forKey: AppConfig.cachedLinkKey) }
    func clearTargetLink() { defaults.removeObject(forKey: AppConfig.cachedLinkKey) }
    var hasCachedLink: Bool { getTargetLink() != nil }
}
