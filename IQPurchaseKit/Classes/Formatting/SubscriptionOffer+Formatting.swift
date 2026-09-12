//
//  SubscriptionOffer+Formatting.swift

import Foundation
import StoreKit

extension ProductInfo {

    public struct SubscriptionOffer: Hashable {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let price: Decimal
        public let displayPrice: String
        public let periodCount: Int
        public let period: ProductInfo.SubscriptionPeriod
        public let paymentMode: Product.SubscriptionOffer.PaymentMode

        public init(
            id: String?,
            type: Product.SubscriptionOffer.OfferType,
            price: Decimal,
            displayPrice: String,
            periodCount: Int,
            period: ProductInfo.SubscriptionPeriod,
            paymentMode: Product.SubscriptionOffer.PaymentMode
        ) {
            self.id = id
            self.type = type
            self.periodCount = periodCount
            self.price = price
            self.displayPrice = displayPrice
            self.period = period
            self.paymentMode = paymentMode
        }

        init(offer: Product.SubscriptionOffer) {
            self.id = offer.id
            self.type = offer.type
            self.price = offer.price
            self.displayPrice = offer.displayPrice
            self.periodCount = offer.periodCount

            if offer.period.unit == .day && offer.period.value == 7 {
                period = .init(unit: .week, value: 1)
            } else if offer.period.unit == .day && offer.period.value == 30 {
                period = .init(unit: .month, value: 1)
            } else if offer.period.unit == .day && offer.period.value == 365 {
                period = .init(unit: .year, value: 1)
            } else if offer.period.unit == .month && offer.period.value == 12 {
                period = .init(unit: .year, value: 1)
            } else {
                period = ProductInfo.SubscriptionPeriod(subscriptionPeriod: offer.period)
            }

            self.paymentMode = offer.paymentMode
        }
    }
}

extension ProductInfo {

    /// Intro price expressed per subscription billing period, for was/now comparison.
    /// Pay as you go uses StoreKit's `displayPrice` when the offer period already matches.
    /// Pay up front always converts the lump sum into the subscription's period.
    var comparableIntroPrice: Decimal? {
        guard let offer = subscription?.introductoryOffer else {
            return nil
        }

        switch offer.paymentMode {
        case .payAsYouGo:
            return convertedIntroPrice(offerPrice: offer.price, introDays: offer.period.days)
        case .payUpFront:
            return convertedIntroPrice(
                offerPrice: offer.price,
                introDays: offer.period.days * offer.periodCount
            )
        default:
            return nil
        }
    }

    /// Whether the intro should use deal chrome (strikethrough, CTA subtitle, etc.).
    /// Pay as you go at the same rate as regular is treated as no offer.
    public var shouldDisplayIntroductoryOffer: Bool {
        guard isEligibleForIntroOffer,
              let offer = subscription?.introductoryOffer else {
            return false
        }

        if offer.paymentMode == .payAsYouGo, isPayAsYouGoAmountSameAsRegular {
            return false
        }

        return true
    }

    private var isPayAsYouGoAmountSameAsRegular: Bool {
        guard let introPrice = comparableIntroPrice else {
            return false
        }
        return NSDecimalNumber(decimal: introPrice - price).doubleValue.magnitude < 0.005
    }

    private func convertedIntroPrice(offerPrice: Decimal, introDays: Int) -> Decimal? {
        guard introDays > 0,
              let subscriptionDays = subscription?.subscriptionPeriod.days,
              subscriptionDays > 0 else {
            return nil
        }

        return offerPrice * Decimal(subscriptionDays) / Decimal(introDays)
    }
}
