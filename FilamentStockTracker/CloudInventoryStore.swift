//
//  CloudInventoryStore.swift
//  FilamentStockTracker
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@MainActor
final class CloudInventoryStore: ObservableObject {
    @Published private(set) var stocks: [StockRow] = []
    @Published private(set) var logs: [LogRow] = []
    @Published var lowStockThreshold: Int = 20
    @Published var lastError: String? = nil
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()

    // MARK: - Firestore paths
    private func uid() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        return uid
    }

    private func stocksCol() -> CollectionReference {
        return db.collection("filaments")  // ortak
    }

    private func logsCol() -> CollectionReference {
        return db.collection("logs")  // ortak
    }
    // MARK: - Refresh (one-shot fetch)
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            lastError = nil

            let stockSnap = try await stocksCol().getDocuments()
            let logSnap = try await logsCol()
                .order(by: "createdAt", descending: true)
                .limit(to: 200)
                .getDocuments()

            // Firestore doc -> StockRow/LogRow map
            let s: [StockRow] = stockSnap.documents.compactMap { doc in
                StockRow(
                    material: (doc.data()["material"] as? String) ?? doc.documentID,
                    quantity: (doc.data()["quantity"] as? Int) ?? 0
                )
            }

            let l: [LogRow] = logSnap.documents.compactMap { doc in
                let d = doc.data()
                return LogRow(
                         id: doc.documentID,
                         created_at: (d["createdAt"] as? Timestamp)?.dateValue(),
                         material: (d["material"] as? String) ?? "",
                         delta: (d["delta"] as? Int) ?? 0,
                         reason: (d["reason"] as? String),
                         user_email: (d["user_email"] as? String)
                )
            }

            self.stocks = s.sorted { $0.material < $1.material }
            self.logs = l
        } catch {
            lastError = error.localizedDescription
        }
    }

    func quantity(for material: MaterialType) -> Int {
        stocks.first(where: { $0.material == material.rawValue })?.quantity ?? 0
    }

    // MARK: - Public actions

    func addStock(material: MaterialType, amount: Int, userEmail: String?) async {
        await adjust(material: material, delta: abs(amount), reason: "Stock In", userEmail: userEmail)
    }

    func subtractStock(material: MaterialType, amount: Int, reason: String, userEmail: String?) async {
        await adjust(material: material, delta: -abs(amount), reason: reason, userEmail: userEmail)
    }

    // MARK: - Internals (transaction)

    private func adjust(material: MaterialType, delta: Int, reason: String, userEmail: String?) async {
        guard delta != 0 else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            lastError = nil

            let stocksCol = stocksCol()
            let logsCol = logsCol()
            
            // ✅ “unique” karşılığı: docID = material
            let stockRef = stocksCol.document(material.rawValue)
            let logRef = logsCol.document()

            // Transaction: stok güncelle + log ekle
            _ = try await db.runTransaction { tx, err -> Any? in
                let snap: DocumentSnapshot
                do {
                    snap = try tx.getDocument(stockRef)
                } catch {
                    err?.pointee = error as NSError
                    return nil
                }

                let current = (snap.data()?["quantity"] as? Int) ?? 0
                let newQty = max(0, current + delta)

                tx.setData([
                    "material": material.rawValue,
                    "quantity": newQty,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: stockRef, merge: true)

                tx.setData([
                    "material": material.rawValue,
                    "delta": delta,
                    "reason": reason,
                    "user_email": userEmail ?? "",
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: logRef)

                return nil
            }

            await refresh()

            let newQty = quantity(for: material)
            if newQty <= lowStockThreshold {
                await notifyLowStock(material: material, quantity: newQty)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Notifications

    func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func notifyLowStock(material: MaterialType, quantity: Int) async {
        await requestNotificationPermissionIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = "Low stock: \(material.rawValue)"
        content.body = "\(material.rawValue) stock is \(quantity). Threshold: \(lowStockThreshold)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "low-\(material.rawValue)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(req)
    }
}

