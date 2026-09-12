//
//  ProductStatus.swift
//  https://github.com/hackiftekhar/IQPurchaseKit
//  Copyright (c) 2025-26 Iftekhar Qurashi.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import StoreKit

public enum ActiveStatus: Sendable {
    case inactive
    case active
    case gracePeriod
    case billingRetryPeriod
    case upcoming
    case unlocked
}

public final class RenewalStatus {

    private let snapshot: RenewalSnapshot

    public let state: Product.SubscriptionInfo.RenewalState
    public let ownershipType: Transaction.OwnershipType?

    public var currentProductID: String? { snapshot.currentProductID }
    public var willAutoRenew: Bool { snapshot.willAutoRenew }
    public var autoRenewPreference: String? { snapshot.autoRenewPreference }
    public var nextRenewalDate: Date? { snapshot.nextRenewalDate }
    public var expirationDate: Date? { snapshot.expirationDate }
    public var gracePeriodExpirationDate: Date? { snapshot.gracePeriodExpirationDate }
    public var isActive: Bool { snapshot.isActive }

    init(from snapshot: RenewalSnapshot) {
        self.snapshot = snapshot
        self.state = snapshot.state
        self.ownershipType = snapshot.ownershipType
    }

    public struct Info {
        public let currentProductID: String
        public let nextProductID: String?
        public let date: Date?
    }

    public var info: Info? {
        switch state {
        case .subscribed, .inBillingRetryPeriod, .inGracePeriod:
            if let currentProductID = currentProductID {
                let date: Date? = nextRenewalDate ?? expirationDate ?? gracePeriodExpirationDate
                if willAutoRenew {
                    return .init(currentProductID: currentProductID, nextProductID: autoRenewPreference, date: date)
                } else {
                    return .init(currentProductID: currentProductID, nextProductID: nil, date: date)
                }
            }
        case .expired, .revoked:
            return nil
        default:
            return nil
        }
        return nil
    }
}

public final class ProductStatus {

    private let snapshot: ProductSnapshot

    public let type: Product.ProductType
    public let renewalInfo: RenewalStatus?

    public var id: String { snapshot.id }
    public var displayName: String { snapshot.displayName }
    public var isEligibleForIntroOffer: Bool { snapshot.isEligibleForIntroOffer }
    public var isFamilyShareable: Bool { snapshot.isFamilyShareable }
    public var status: ActiveStatus { snapshot.status }

    /// True when StoreKit reports an active entitlement (subscribed / grace).
    /// Billing retry is `.billingRetryPeriod` with `isActive == false`.
    public var isActive: Bool {
        renewalInfo?.isActive ?? false
    }

    init(from snapshot: ProductSnapshot) {
        self.snapshot = snapshot
        self.type = snapshot.type

        if let renewalInfo = snapshot.renewalInfo {
            self.renewalInfo = .init(from: renewalInfo)
        } else {
            self.renewalInfo = nil
        }
    }
}
