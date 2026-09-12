//
//  SubscriptionPeriod+Formatting.swift

import StoreKit

extension ProductInfo {

    public struct SubscriptionPeriod: Hashable {
        public let unit: Product.SubscriptionPeriod.Unit
        public let value: Int

        public init(unit: Product.SubscriptionPeriod.Unit, value: Int) {
            self.unit = unit
            self.value = value
        }

        init(subscriptionPeriod: Product.SubscriptionPeriod) {
            self.unit = subscriptionPeriod.unit
            self.value = subscriptionPeriod.value
        }

        public var days: Int {
            switch unit {
            case .day:
                return value
            case .week:
                return value * 7
            case .month:
                return value * 30
            case .year:
                return value * 365
            @unknown default:
                return 0
            }
        }
    }
}
