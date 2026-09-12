//
//  DefaultPaywallTextFormatting.swift

import Foundation
import StoreKit

public struct DefaultPaywallTextFormatting: PaywallTextFormatting {

    public init() {}

    // MARK: - Loading / error

    public func loadingPlansTitle() -> String {
        String(localized: "Loading plans...")
    }

    public func plansErrorTitle() -> String {
        String(localized: "Error")
    }

    public func retryButtonTitle() -> String {
        String(localized: "Retry")
    }

    // MARK: - Badges

    public func activeBadgeTitle(for product: ProductInfo) -> String {
        String(localized: product.type == .nonConsumable ? "UNLOCKED" : "ACTIVE")
    }

    // MARK: - Price columns

    public func regularPriceColumn(for product: ProductInfo) -> PaywallPriceColumnTexts {
        PaywallPriceColumnTexts(
            primaryPrice: compactPrice(product.displayPrice),
            cadence: subscriptionPeriodDescription(for: product)
        )
    }

    public func introductoryOfferPriceColumn(
        for product: ProductInfo,
        offer: ProductInfo.SubscriptionOffer
    ) -> PaywallPriceColumnTexts {
        let cadence = subscriptionPeriodDescription(for: product)
        let duration = offerDurationDescription(offer)

        switch offer.paymentMode {
        case .payUpFront:
            return PaywallPriceColumnTexts(
                strikethroughPrice: compactPrice(product.displayPrice),
                primaryPrice: compactPrice(comparableIntroDisplayPrice(for: product) ?? offer.displayPrice),
                cadence: cadence,
                footnote: "\(compactPrice(offer.displayPrice)) \(String(localized: "for first")) \(duration)"
            )
        case .payAsYouGo:
            return PaywallPriceColumnTexts(
                strikethroughPrice: compactPrice(product.displayPrice),
                primaryPrice: compactPrice(comparableIntroDisplayPrice(for: product) ?? offer.displayPrice),
                cadence: cadence,
                footnote: "\(String(localized: "for first")) \(duration)"
            )
        case .freeTrial:
            return PaywallPriceColumnTexts(
                primaryPrice: compactPrice(product.displayPrice),
                cadence: cadence,
                footnote: "\(String(localized: "Free for first")) \(duration)"
            )
        default:
            return regularPriceColumn(for: product)
        }
    }

    // MARK: - Subscription status

    public func subscriptionStatusTexts(
        currentPlan: ProductStatus,
        renewalInfo: RenewalStatus.Info,
        nextPlanDisplayName: String?
    ) -> PaywallStatusTexts? {
        let dateString = formatStatusDate(renewalInfo.date)

        switch currentPlan.type {
        case .autoRenewable:
            switch currentPlan.status {
            case .active, .upcoming:
                if renewalInfo.currentProductID == renewalInfo.nextProductID {
                    return PaywallStatusTexts(
                        title: "'\(currentPlan.displayName)' Renews Automatically",
                        message: "Your subscription will renew on \(dateString)"
                    )
                } else if let nextProductID = renewalInfo.nextProductID,
                          renewalInfo.currentProductID != nextProductID {
                    let nextName = nextPlanDisplayName ?? nextProductID
                    return PaywallStatusTexts(
                        title: "Upcoming Plan Change",
                        message: "Starting \(dateString), your plan will change from '\(currentPlan.displayName)' to '\(nextName)'"
                    )
                } else {
                    return PaywallStatusTexts(
                        title: "'\(currentPlan.displayName)' Subscription Cancelled",
                        message: "Your subscription will remain active until \(dateString)"
                    )
                }
            case .gracePeriod:
                return PaywallStatusTexts(
                    title: "Payment Issue",
                    message: "We couldn't process your payment. Your '\(currentPlan.displayName)' subscription remains active until \(dateString). Please update your payment method to avoid losing access."
                )
            case .billingRetryPeriod:
                return PaywallStatusTexts(
                    title: "Payment Issue",
                    message: "We couldn't process your payment for your '\(currentPlan.displayName)' subscription. Apple is retrying the payment. Please update your payment method to restore your subscription."
                )
            case .inactive, .unlocked:
                return nil
            }
        case .nonRenewable:
            return PaywallStatusTexts(
                title: "'\(currentPlan.displayName)' Active",
                message: "Your subscription will remain active until \(dateString)"
            )
        case .consumable, .nonConsumable:
            return nil
        default:
            return nil
        }
    }

    // MARK: - CTA

    public func callToActionTitle(
        selectedProduct: ProductInfo?,
        isPurchasing: Bool,
        isLoadingEmptyProducts: Bool
    ) -> String {
        if isPurchasing {
            return String(localized: "Please wait...")
        }

        if isLoadingEmptyProducts {
            return String(localized: "Loading...")
        }

        guard let product = selectedProduct else {
            return String(localized: "Choose your plan")
        }

        if product.isActive {
            if product.type == .autoRenewable || product.type == .nonRenewable {
                return String(localized: "Manage Subscription")
            }
            return String(localized: "Unlocked")
        }

        if product.shouldDisplayIntroductoryOffer,
           let offer = product.subscription?.introductoryOffer {
            return offerActionTitle(offer)
        }

        return "\(String(localized: "Subscribe")) \(compactPrice(product.displayPrice))"
    }

    public func callToActionSubtitle(
        selectedProduct: ProductInfo?,
        isPurchasing: Bool,
        isLoadingEmptyProducts: Bool
    ) -> String? {
        if isPurchasing || isLoadingEmptyProducts {
            return nil
        }

        guard let product = selectedProduct, !product.isActive else {
            return nil
        }

        if product.shouldDisplayIntroductoryOffer,
           let offer = product.subscription?.introductoryOffer {
            let thenPrice = thenPriceDescription(for: product)
            switch offer.paymentMode {
            case .payAsYouGo:
                return "for \(offerDurationDescription(offer)), then \(thenPrice)"
            case .freeTrial, .payUpFront:
                return "then \(thenPrice)"
            default:
                return "then \(thenPrice)"
            }
        }

        return subscriptionPeriodDescription(for: product)
    }

    // MARK: - Manage / restore / redeem

    public func manageSubscriptionTitle() -> String {
        String(localized: "Manage Subscription")
    }

    public func restorePurchasesTitle() -> String {
        String(localized: "Restore")
    }

    public func redeemCodeTitle() -> String {
        String(localized: "Redeem")
    }

    // MARK: - Alerts

    public func selectPlanAlert() -> PaywallAlertTexts {
        PaywallAlertTexts(
            title: String(localized: "Select a Plan"),
            message: String(localized: "Please select a subscription plan to continue.")
        )
    }

    public func purchaseResultAlert(state: PurchaseState, isRestore: Bool) -> PaywallAlertTexts? {
        switch state {
        case .success:
            if isRestore {
                return PaywallAlertTexts(
                    title: "Restored",
                    message: "Purchase Restored completed successfully!"
                )
            }
            return PaywallAlertTexts(
                title: "Success",
                message: "Purchase completed successfully!"
            )
        case .restored:
            return PaywallAlertTexts(
                title: "Restored",
                message: "Purchase Restored completed successfully!"
            )
        case .pending:
            if isRestore {
                return PaywallAlertTexts(
                    title: "Purchase Restored Pending",
                    message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase."
                )
            }
            return PaywallAlertTexts(
                title: "Purchase Pending",
                message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase."
            )
        case .userCancelled:
            return nil
        case .failure(let error):
            if isRestore {
                return PaywallAlertTexts(
                    title: "Purchase Restoration Failed",
                    message: error.localizedDescription
                )
            }
            return PaywallAlertTexts(
                title: "Purchase Failed",
                message: error.localizedDescription
            )
        }
    }
}

// MARK: - Private helpers (period / offer / price copy)

extension DefaultPaywallTextFormatting {

    func compactPrice(_ price: String) -> String {
        price.replacingOccurrences(of: ".00", with: "")
    }

    func formatStatusDate(_ date: Date?) -> String {
        date?.formatted(.dateTime.hour().minute().month().day().year()) ?? ""
    }

    func unitLabel(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        @unknown default: return ""
        }
    }

    func periodFormatted(_ period: ProductInfo.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 7 {
                return "Week"
            }
            return period.value == 1 ? "Day" : "\(period.value) Days"
        case .week:
            return period.value == 1 ? "Week" : "\(period.value) Weeks"
        case .month:
            return period.value == 1 ? "Month" : "\(period.value) Months"
        case .year:
            return period.value == 1 ? "Year" : "\(period.value) Years"
        @unknown default:
            return ""
        }
    }

    func periodLocalizedDescription(_ period: ProductInfo.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 7 {
                return "1 Week"
            } else if period.value == 14 {
                return "2 Weeks"
            }
            return "\(period.value) Day\(period.value == 1 ? "" : "s")"
        case .week:
            return "\(period.value) Week\(period.value == 1 ? "" : "s")"
        case .month:
            return "\(period.value) Month\(period.value == 1 ? "" : "s")"
        case .year:
            return "\(period.value) Year\(period.value == 1 ? "" : "s")"
        @unknown default:
            return ""
        }
    }

    func offerDurationDescription(_ offer: ProductInfo.SubscriptionOffer) -> String {
        let multiplied = ProductInfo.SubscriptionPeriod(
            unit: offer.period.unit,
            value: offer.period.value * max(offer.periodCount, 1)
        )
        return periodLocalizedDescription(multiplied)
    }

    func subscriptionPeriodDescription(for product: ProductInfo) -> String? {
        switch product.type {
        case .nonConsumable:
            return "Lifetime"
        case .autoRenewable:
            if let period = product.subscription?.subscriptionPeriod {
                return "per " + periodFormatted(period)
            }
        case .nonRenewable:
            if let period = product.subscription?.subscriptionPeriod {
                return periodFormatted(period)
            }
        case .consumable:
            fallthrough
        default:
            break
        }
        return nil
    }

    func thenPriceDescription(for product: ProductInfo) -> String {
        [product.displayPrice, subscriptionPeriodDescription(for: product)]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    func comparableIntroDisplayPrice(for product: ProductInfo) -> String? {
        guard let equivalent = product.comparableIntroPrice else {
            return nil
        }

        if let subscription = product.subscription,
           let offer = subscription.introductoryOffer,
           offer.paymentMode == .payAsYouGo,
           offer.period.days == subscription.subscriptionPeriod.days {
            return offer.displayPrice
        }

        return equivalent.formatted(product.priceFormatStyle)
    }

    func offerActionTitle(_ offer: ProductInfo.SubscriptionOffer) -> String {
        let duration = offerDurationDescription(offer)
        switch offer.type {
        case .introductory:
            switch offer.paymentMode {
            case .freeTrial:
                return "Start \(duration) Free Trial"
            case .payUpFront:
                return "Pay \(offer.displayPrice) for \(duration)"
            case .payAsYouGo:
                return "Subscribe \(offer.displayPrice) per \(unitLabel(offer.period.unit))"
            default:
                break
            }
        case .promotional:
            switch offer.paymentMode {
            case .freeTrial:
                return "Subscribe Free for \(duration)"
            case .payUpFront:
                return "Pay \(offer.displayPrice) for \(duration)"
            case .payAsYouGo:
                return "Subscribe \(offer.displayPrice) per \(unitLabel(offer.period.unit))"
            default:
                break
            }
        default:
            break
        }
        return "Subscribe \(offer.displayPrice) per \(unitLabel(offer.period.unit))"
    }
}
