//
//  PaywallTextFormatting.swift

import Foundation
import StoreKit

public struct PaywallPriceColumnTexts: Hashable {
    public var strikethroughPrice: String?
    public var primaryPrice: String
    public var cadence: String?
    public var footnote: String?

    public init(
        strikethroughPrice: String? = nil,
        primaryPrice: String,
        cadence: String? = nil,
        footnote: String? = nil
    ) {
        self.strikethroughPrice = strikethroughPrice
        self.primaryPrice = primaryPrice
        self.cadence = cadence
        self.footnote = footnote
    }
}

public struct PaywallStatusTexts: Hashable {
    public var title: String
    public var message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

public struct PaywallAlertTexts: Hashable {
    public var title: String
    public var message: String
    public var buttonTitle: String

    public init(title: String, message: String, buttonTitle: String = "OK") {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }
}

/// Contract for paywall display copy. Custom paywalls can use
/// `DefaultPaywallTextFormatting` or supply their own implementation.
public protocol PaywallTextFormatting {
    func loadingPlansTitle() -> String
    func plansErrorTitle() -> String
    func retryButtonTitle() -> String

    func activeBadgeTitle(for product: ProductInfo) -> String

    func regularPriceColumn(for product: ProductInfo) -> PaywallPriceColumnTexts
    func introductoryOfferPriceColumn(
        for product: ProductInfo,
        offer: ProductInfo.SubscriptionOffer
    ) -> PaywallPriceColumnTexts

    func subscriptionStatusTexts(
        currentPlan: ProductStatus,
        renewalInfo: RenewalStatus.Info,
        nextPlanDisplayName: String?
    ) -> PaywallStatusTexts?

    func callToActionTitle(
        selectedProduct: ProductInfo?,
        isPurchasing: Bool,
        isLoadingEmptyProducts: Bool
    ) -> String

    func callToActionSubtitle(
        selectedProduct: ProductInfo?,
        isPurchasing: Bool,
        isLoadingEmptyProducts: Bool
    ) -> String?

    func manageSubscriptionTitle() -> String
    func restorePurchasesTitle() -> String
    func redeemCodeTitle() -> String

    func selectPlanAlert() -> PaywallAlertTexts
    func purchaseResultAlert(state: PurchaseState, isRestore: Bool) -> PaywallAlertTexts?
}
