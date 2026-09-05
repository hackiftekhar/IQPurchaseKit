//
//  PaywallViewModel.swift

import Combine
import Foundation
import StoreKit
import UIKit

@MainActor
public final class PaywallViewModel: ObservableObject {

    private let purchaseKit = PurchaseKit.shared
    private let purchaseStatusManager = PurchaseStatusManager.shared
    private var purchaseStatusObserver: NSObjectProtocol?

    @MainActor
    @Published public var products: [ProductInfo] = []

    @MainActor
    @Published @objc public var isProductLoading: Bool = false

    @MainActor
    @Published @objc public var isProductPurchasing: Bool = false

    public init() {
        purchaseStatusObserver = NotificationCenter.default.addObserver(
            forName: PurchaseStatusManager.purchaseStatusDidChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateProductStatuses()
        }
    }

    deinit {
        if let purchaseStatusObserver {
            NotificationCenter.default.removeObserver(purchaseStatusObserver)
        }
    }

    private func updateProductStatuses() {
        let products = self.products.map { productInfo in
            var updatedProductInfo = productInfo
            updatedProductInfo.updateSnapshot(purchaseStatusManager.snapshot(for: productInfo.id))
            return updatedProductInfo
        }
        self.products = products
    }

    public func fetchProducts(productIds: [String]) async throws {
        var cachedProducts = [Product]()

        for productId in productIds {
            if let cachedProduct = purchaseKit.product(withID: productId) {
                cachedProducts.append(cachedProduct)
            }
        }
        if !cachedProducts.isEmpty {
            self.products = cachedProducts.map({ .init(product: $0, snapshot: purchaseStatusManager.snapshot(for: $0.id)) })
        }

        isProductLoading = true
        defer { isProductLoading = false }

        let products = try await purchaseKit.loadProducts(productIDs: productIds)
        if !products.isEmpty {
            self.products = products.map({ .init(product: $0, snapshot: purchaseStatusManager.snapshot(for: $0.id)) })
        }

        if self.products.isEmpty {
            throw NSError(domain: "PaywallViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No products to show"])
        }
    }

    public func purchase(product: ProductInfo, quantity: Int? = nil) async -> PurchaseState {
        guard let actualProduct = purchaseKit.product(withID: product.id) else {
            return .failure(error: NSError(domain: "PaywallViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "No product found for \(product.id)"]))
        }

        isProductPurchasing = true
        defer { isProductPurchasing = false }

        let finalQuantity: Int? = product.type == .consumable ? quantity : nil
        return await purchaseKit.purchase(product: actualProduct, quantity: finalQuantity)
    }

    public func restorePurchases() async -> PurchaseState {
        isProductPurchasing = true
        defer { isProductPurchasing = false }
        return await purchaseKit.restorePurchases()
    }

    @objc public func presentCodeRedemptionSheet() {
        purchaseKit.presentCodeRedemptionSheet()
    }

    public func beginRefundRequest(for productID: String, in scene: UIWindowScene) async -> Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        await purchaseKit.beginRefundRequest(for: productID, in: scene)
    }
}
