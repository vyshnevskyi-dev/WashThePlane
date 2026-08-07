//
//  NetworkService.swift
//  WashThePlane
//
//  Все запросы — на один хост: POST https://webver.men
//

import Foundation

final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = AppConfig.networkTimeout
        c.timeoutIntervalForResource = AppConfig.networkTimeout
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    // MARK: - checkRoute

    /// POST {hostBaseURL}  body: {"client_id": ..., "app_id": "id..."}
    func checkRoute(clientID: String, appID: String) async -> String? {
        let urlString = AppConfig.hostBaseURL
        guard let url = URL(string: urlString) else { return nil }

        let body: [String: Any] = ["client_id": clientID, "app_id": appID]
        log("→ POST \(urlString)")
        log("→ BODY: \(pretty(body))")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await session.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let raw = String(data: data, encoding: .utf8) ?? "<nil>"
            log("← RESPONSE [\(code)]: \(raw)")

            guard code == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                log("← Bad JSON")
                return nil
            }

            // date может быть строкой или массивом строк
            let link: String? = {
                if let s = json[AppConfig.linkJSONKey] as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return s
                }
                if let arr = json[AppConfig.linkJSONKey] as? [String],
                   let first = arr.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    return first
                }
                return nil
            }()

            guard let link else {
                log("← No usable link (key: '\(AppConfig.linkJSONKey)')")
                return nil
            }
            return link
        } catch {
            log("← ERROR: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - pushToken

    /// POST {hostBaseURL}  body: {"client_id": ..., "app_id": "id...", "pushToken": "..."}
    func registerPushToken(clientID: String, appID: String, pushToken: String) {
        let urlString = AppConfig.hostBaseURL
        guard let url = URL(string: urlString) else { return }

        let body: [String: Any] = [
            "client_id": clientID,
            "app_id": appID,
            "pushToken": pushToken
        ]
        log("→ POST \(urlString)")
        log("→ BODY: \(pretty(body))")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: req) { data, resp, error in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if let error {
                print("[WTP] ← pushToken ERROR: \(error.localizedDescription)")
            } else {
                let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<nil>"
                print("[WTP] ← pushToken RESPONSE [\(code)]: \(raw)")
            }
        }.resume()
    }

    // MARK: - pushClick

    /// POST {hostBaseURL}  body: {"client_id": ..., "pushID": "..."}
    func trackPushClick(clientID: String, pushID: String) {
        let urlString = AppConfig.hostBaseURL
        guard let url = URL(string: urlString) else { return }

        let body: [String: Any] = [
            "client_id": clientID,
            "pushID": pushID
        ]
        log("→ POST \(urlString)")
        log("→ BODY: \(pretty(body))")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: req) { data, resp, error in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if let error {
                print("[WTP] ← pushClick ERROR: \(error.localizedDescription)")
            } else {
                let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<nil>"
                print("[WTP] ← pushClick RESPONSE [\(code)]: \(raw)")
            }
        }.resume()
    }

    // MARK: - Helpers

    private func log(_ msg: String) { print("[WTP] \(msg)") }

    private func pretty(_ dict: [String: Any]) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let s = String(data: d, encoding: .utf8) else { return "\(dict)" }
        return s
    }
}
