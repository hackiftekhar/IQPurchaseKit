//
//  SubscriptionOffer+Formatting

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

        init(id: String?, type: Product.SubscriptionOffer.OfferType, price: Decimal, displayPrice: String, periodCount: Int, period: ProductInfo.SubscriptionPeriod, paymentMode: Product.SubscriptionOffer.PaymentMode) {
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

        /// Full intro window, including `periodCount` (e.g. "2 Months", "3 Months", "2 Weeks").
        public var durationDescription: String {
            period.localizedDescription(multipliedBy: periodCount)
        }

        public var actionTitle: String {
            let duration = durationDescription
            switch type {
            case .introductory:
                switch paymentMode {
                case .freeTrial:
                    return "Start \(duration) Free Trial"
                case .payUpFront:
                    return "Pay \(displayPrice) for \(duration)"
                case .payAsYouGo:
                    return "Subscribe \(displayPrice) per \(period.unit.formatted)"
                default: break
                }
            case .promotional:
                switch paymentMode {
                case .freeTrial:
                    return "Subscribe Free for \(duration)"
                case .payUpFront:
                    return "Pay \(displayPrice) for \(duration)"
                case .payAsYouGo:
                    return "Subscribe \(displayPrice) per \(period.unit.formatted)"
                default: break
                }
            default: break
            }

            return "Subscribe \(displayPrice) per \(period.unit.formatted)"
        }

        public var localizedDescription: String {
            let duration = durationDescription
            switch type {
            case .introductory:
                switch paymentMode {
                case .freeTrial:
                    return "\(duration) Free Trial"
                case .payUpFront:
                    return "\(displayPrice) for \(duration)"
                case .payAsYouGo:
                    return "\(displayPrice) per \(period.unit.formatted) for \(duration)"
                default: break
                }
            case .promotional:
                switch paymentMode {
                case .freeTrial:
                    return "Free for \(duration)"
                case .payUpFront:
                    return "\(displayPrice) for \(duration)"
                case .payAsYouGo:
                    return "\(displayPrice) per \(period.unit.formatted) for \(duration)"
                default: break
                }
            default: break
            }

            return "\(displayPrice) per \(period.unit.formatted) for \(duration)"
        }
    }
}

extension ProductInfo {

    /// Regular price plus cadence, e.g. "$0.39 per Week".
    public var thenPriceDescription: String {
        [displayPrice, subscriptionPeriodDescription]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    /// Intro price expressed per subscription billing period, for was/now comparison.
    /// Pay as you go uses StoreKit's `displayPrice` when the offer period already matches.
    /// Pay up front always converts the lump sum into the subscription's period.
    public var comparableIntroDisplayPrice: String? {
        guard let equivalent = comparableIntroPrice else {
            return nil
        }

        if let subscription,
           let offer = subscription.introductoryOffer,
           offer.paymentMode == .payAsYouGo,
           offer.period.days == subscription.subscriptionPeriod.days {
            return offer.displayPrice
        }

        return equivalent.formatted(priceFormatStyle)
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

    public var subscribeActionTitle: String {
        guard shouldDisplayIntroductoryOffer,
              let offer = subscription?.introductoryOffer else {
            return "Subscribe \(displayPrice)"
        }
        return offer.actionTitle
    }

    public var subscribeActionSubtitle: String? {
        guard shouldDisplayIntroductoryOffer,
              let offer = subscription?.introductoryOffer else {
            return subscriptionPeriodDescription
        }

        let thenPrice = thenPriceDescription
        switch offer.paymentMode {
        case .payAsYouGo:
            return "for \(offer.durationDescription), then \(thenPrice)"
        case .freeTrial, .payUpFront:
            return "then \(thenPrice)"
        default:
            return "then \(thenPrice)"
        }
    }

    private var comparableIntroPrice: Decimal? {
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
