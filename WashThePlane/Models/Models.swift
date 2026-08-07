//
//  Models.swift
//  WashThePlane
//
//  Доменные модели приложения.
//

import UIKit

// MARK: - Wash Package

struct WashPackage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let currency: String
    let durationMinutes: Int
    let icon: String            // SF Symbol name
    let includes: [String]
    let isPopular: Bool
    let category: PackageCategory

    enum PackageCategory: String, CaseIterable {
        case exterior = "Exterior"
        case interior = "Interior"
        case full     = "Full Service"
        case premium  = "Premium"
    }
}

// MARK: - Preset Packages

extension WashPackage {
    static let all: [WashPackage] = [
        WashPackage(
            name: "Quick Rinse",
            description: "Express exterior wash. Perfect between flights.",
            price: 890, currency: "EUR", durationMinutes: 45,
            icon: "drop.fill",
            includes: ["Pressure wash", "Spot-free rinse", "Landing gear clean"],
            isPopular: false, category: .exterior
        ),
        WashPackage(
            name: "Silver Foam",
            description: "Deep foam bath with hand dry. Removes jet fuel residue.",
            price: 1490, currency: "EUR", durationMinutes: 90,
            icon: "bubbles.and.sparkles.fill",
            includes: ["pH-neutral foam", "Hand dry", "Window polish", "De-icing prep"],
            isPopular: false, category: .exterior
        ),
        WashPackage(
            name: "Cockpit Detail",
            description: "Interior deep clean. Cockpit, cabin, galley.",
            price: 1290, currency: "EUR", durationMinutes: 120,
            icon: "sparkles",
            includes: ["Leather conditioning", "Carpet shampoo", "Panel wipe-down", "Odor neutralizer"],
            isPopular: false, category: .interior
        ),
        WashPackage(
            name: "Gold Wing",
            description: "Full exterior + interior. Our most popular package.",
            price: 2190, currency: "EUR", durationMinutes: 180,
            icon: "crown.fill",
            includes: ["Silver Foam exterior", "Cockpit Detail interior", "Anti-corrosion coat", "Tire shine", "Engine bay rinse"],
            isPopular: true, category: .full
        ),
        WashPackage(
            name: "Black Jet Elite",
            description: "VIP treatment. Concierge pickup, same-day service, ceramic coat.",
            price: 4990, currency: "EUR", durationMinutes: 360,
            icon: "star.fill",
            includes: ["All Gold Wing services", "Ceramic coating", "Concierge pickup", "Same-day guarantee", "Champagne lounge", "Post-wash inspection report"],
            isPopular: false, category: .premium
        ),
        WashPackage(
            name: "Hangar Fleet",
            description: "Corporate fleet plan. Up to 5 aircraft per month.",
            price: 12990, currency: "EUR", durationMinutes: 0,
            icon: "building.2.fill",
            includes: ["Priority scheduling", "Dedicated crew", "Monthly reports", "Bulk discount", "24/7 support"],
            isPopular: false, category: .premium
        )
    ]
}

// MARK: - Order

struct Order: Identifiable {
    let id = UUID()
    let package: WashPackage
    let aircraftRegistration: String
    let date: Date
    let airport: String
    let country: String
    var status: OrderStatus

    enum OrderStatus: String, CaseIterable {
        case confirmed  = "Confirmed"
        case enRoute    = "Crew En Route"
        case inProgress = "Wash in Progress"
        case completed  = "Completed"
        case cancelled  = "Cancelled"

        var icon: String {
            switch self {
            case .confirmed:  return "checkmark.circle.fill"
            case .enRoute:    return "truck.box.fill"
            case .inProgress: return "arrow.triangle.2.circlepath"
            case .completed:  return "flag.checkered.circle.fill"
            case .cancelled:  return "xmark.circle.fill"
            }
        }

        var color: UIColor {
            switch self {
            case .confirmed:  return Theme.warning
            case .enRoute:    return Theme.warning
            case .inProgress: return Theme.accent
            case .completed:  return Theme.success
            case .cancelled:  return Theme.textTertiary
            }
        }

        var step: Int {
            switch self {
            case .confirmed:  return 0
            case .enRoute:    return 1
            case .inProgress: return 2
            case .completed:  return 3
            case .cancelled:  return -1
            }
        }
    }
}

// MARK: - Country

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let flag: String
    let code: String          // ISO 3166-1 alpha-2
    let airports: [String]
    let isAvailable: Bool
    let washingSurchargePct: Double  // дополнительный % к цене
}

extension Country {
    static let europe: [Country] = [
        Country(name: "France",         flag: "🇫🇷", code: "FR", airports: ["Paris Le Bourget (LBG)", "Nice Côte d'Azur (NCE)", "Lyon Bron (LYN)"], isAvailable: true,  washingSurchargePct: 0),
        Country(name: "Germany",        flag: "🇩🇪", code: "DE", airports: ["Munich Oberpfaffenhofen (OBF)", "Berlin Brandenburg (BER)", "Hamburg (HAM)"], isAvailable: true,  washingSurchargePct: 5),
        Country(name: "United Kingdom", flag: "🇬🇧", code: "GB", airports: ["London Luton (LTN)", "Farnborough (FAB)", "Manchester (MAN)"], isAvailable: true,  washingSurchargePct: 10),
        Country(name: "Switzerland",    flag: "🇨🇭", code: "CH", airports: ["Geneva (GVA)", "Zurich (ZRH)", "Sion (SIR)"], isAvailable: true,  washingSurchargePct: 15),
        Country(name: "Italy",          flag: "🇮🇹", code: "IT", airports: ["Milan Linate (LIN)", "Rome Ciampino (CIA)", "Olbia Costa Smeralda (OLB)"], isAvailable: true,  washingSurchargePct: 0),
        Country(name: "Spain",          flag: "🇪🇸", code: "ES", airports: ["Madrid Torrejón (TOJ)", "Barcelona El Prat (BCN)", "Palma de Mallorca (PMI)"], isAvailable: true,  washingSurchargePct: 0),
        Country(name: "Austria",        flag: "🇦🇹", code: "AT", airports: ["Vienna Schwechat (VIE)", "Salzburg (SZG)", "Innsbruck (INN)"], isAvailable: true,  washingSurchargePct: 5),
        Country(name: "Monaco",         flag: "🇲🇨", code: "MC", airports: ["Nice Côte d'Azur (NCE) — helipad"], isAvailable: true,  washingSurchargePct: 25),
        Country(name: "Sweden",         flag: "🇸🇪", code: "SE", airports: ["Stockholm Bromma (BMA)", "Gothenburg (GOT)"], isAvailable: true,  washingSurchargePct: 10),
        Country(name: "Netherlands",    flag: "🇳🇱", code: "NL", airports: ["Amsterdam Schiphol (AMS)", "Rotterdam The Hague (RTM)"], isAvailable: true,  washingSurchargePct: 5),
        Country(name: "Belgium",        flag: "🇧🇪", code: "BE", airports: ["Brussels (BRU)", "Antwerp (ANR)"], isAvailable: true,  washingSurchargePct: 5),
        Country(name: "Portugal",       flag: "🇵🇹", code: "PT", airports: ["Lisbon (LIS)", "Faro (FAO)", "Porto (OPO)"], isAvailable: true,  washingSurchargePct: 0),
        Country(name: "Norway",         flag: "🇳🇴", code: "NO", airports: ["Oslo Gardermoen (OSL)", "Bergen (BGO)"], isAvailable: true,  washingSurchargePct: 15),
        Country(name: "Czech Republic", flag: "🇨🇿", code: "CZ", airports: ["Prague Václav Havel (PRG)"], isAvailable: true,  washingSurchargePct: 0),
        Country(name: "Poland",         flag: "🇵🇱", code: "PL", airports: ["Warsaw Chopin (WAW)", "Kraków (KRK)"], isAvailable: true,  washingSurchargePct: 0),
    ]
}
