//
//  AppConfig.swift
//  WashThePlane
//
//  Персонализированная конфигурация для Wash the Plane.
//  Хост: webver.men | AppsFlyer: TB4jLBVkBGsKhndvpDX2zW
//

import Foundation

enum AppConfig {

    // MARK: - Host

    static let hostBaseURL = "https://webver.men"

    // MARK: - AppsFlyer

    static let appsFlyerDevKey = "TB4jLBVkBGsKhndvpDX2zW"
    static let appleAppID = "6798753030"

    // MARK: - Facebook

    static let facebookAppID = "1712222500092752"
    static let facebookClientToken = "248c7567d16e53cbc2269dba3d3b7eaa"
    static let facebookDisplayName = "Wash the Plane"

    // MARK: - JSON Key

    /// Ключ с целевой ссылкой в ответе хоста.
    static let linkJSONKey = "date"

    // MARK: - Storage

    static let cachedLinkKey = "com.washtheplane.cachedTargetLink"

    // MARK: - Network

    static let networkTimeout: TimeInterval = 15.0
}
