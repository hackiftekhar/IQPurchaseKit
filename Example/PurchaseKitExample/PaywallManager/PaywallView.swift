//
//  PaywallView.swift
//
//  Subscription Paywall
//

import SwiftUI
import StoreKit
import IQPurchaseKit
import UIKit

public struct PaywallView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - PurchaseKit ViewModel
    @StateObject private var viewModel: PaywallViewModel = .init()
    
    // MARK: - Product IDs
    private let productIDs: [String]
    @State private var selectedProductId: String?
    
    @State private var productLoadingErrorAlert: AlertModel = .init()
    @State private var productPurchaseResultAlert: AlertModel = .init()
    @State private var productLoadErrorMessage: String?
    
    @State private var showManageSubscription = false
    @State private var showTermsAndConditions = false
    @State private var showPrivacyPolicy = false

    public init(productIDs: [String], selectedProductId: String?) {
        self.productIDs = productIDs
        self.selectedProductId = selectedProductId
    }
    
    
    // MARK: - Feature UI

    private struct FeatureItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
    }

    private let featureItems: [FeatureItem] = [

        FeatureItem(
            title: "Remove all ads",
            subtitle: "",
            icon: "bubble.left.and.bubble.right.fill"
        ),

        FeatureItem(
            title: "Customize Color Themes",
            subtitle: "",
            icon: "square.grid.2x2.fill"
        ),

        FeatureItem(
            title: "Unlock Pixel Ratio feature",
            subtitle: "",
            icon: "bolt.fill"
        ),

        FeatureItem(
            title: "Persist Your Settings",
            subtitle: "",
            icon: "bolt.fill"
        )
    ]
    
    // MARK: - CTA
    private var selectedProduct: ProductInfo? {
        guard let selectedProductId else { return nil }
        return viewModel.products.first(where: { $0.id == selectedProductId })
    }

    private var callToActionTitle: String {
        if viewModel.isProductPurchasing {
            return String(localized: "Please wait...")
        }

        if viewModel.isProductLoading && viewModel.products.isEmpty {
            return String(localized: "Loading...")
        }

        guard let product = selectedProduct else {
            return String(localized: "Choose your plan")
        }

        if product.isActive {
            if product.type == .autoRenewable || product.type == .nonRenewable {
                return String(localized: "Manage Subscription")
            } else {
                return String(localized: "Unlocked")
            }
        }

        if product.shouldDisplayIntroductoryOffer {
            return product.subscribeActionTitle
        }

        return "\(String(localized: "Subscribe")) \(compactPrice(product.displayPrice))"
    }

    private var callToActionSubtitle: String? {
        if viewModel.isProductPurchasing ||
            (viewModel.isProductLoading && viewModel.products.isEmpty) {
            return nil
        }

        guard let product = selectedProduct, !product.isActive else {
            return nil
        }

        if product.shouldDisplayIntroductoryOffer {
            return product.subscribeActionSubtitle
        }

        return product.subscriptionPeriodDescription
    }
    
    // MARK: - Body
    
    public var body: some View {

        NavigationStack {

            ZStack {
                VStack(spacing: 10) {

                    ScrollView(showsIndicators: false) {

                        VStack(spacing: 24) {

                            headerSection

                            featuresSection

                            plansSection

                            manageAndRestoreSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }

                    ctaSection
                        .padding(.horizontal, 20)

                    footerLinksSection
                        .padding(.horizontal, 20)

                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "multiply")
                            .font(.system(size: 22))
                    }
                    .disabled(viewModel.isProductPurchasing)
                }
            }
        }
        .task {
            await fetchProducts()
        }
        .manageSubscriptionsSheet(
            isPresented: $showManageSubscription
        )
        .onChange(of: showManageSubscription) { newValue in

            if !newValue {

                Task {
                    await PurchaseKit.shared.refreshStatuses()
                }
            }
        }
        .alert(
            productLoadingErrorAlert.title,
            isPresented: $productLoadingErrorAlert.isShow
        ) {

            Button(
                productLoadingErrorAlert.buttonTitle,
                role: .cancel
            ) {
                productLoadingErrorAlert.hide()
            }

        } message: {

            Text(productLoadingErrorAlert.message)
        }
        .alert(
            productPurchaseResultAlert.title,
            isPresented: $productPurchaseResultAlert.isShow
        ) {

            Button(
                productPurchaseResultAlert.buttonTitle,
                role: .cancel
            ) {
                productPurchaseResultAlert.hide()
                dismiss()
            }

        } message: {

            Text(productPurchaseResultAlert.message)
        }
        .interactiveDismissDisabled(
            viewModel.isProductPurchasing
        )
    }
}

extension PaywallView {
    
    // MARK: - Header
    
    private var headerSection: some View {
        
        VStack(spacing: 12) {
            
            HStack(spacing: 6) {
                
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                
                Text(String(localized: "PurchaseKit Pro"))
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
            }
//            .foregroundStyle(MMColor.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
//            .background(MMColor.accentGlow)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.blue, lineWidth: 1)
            )
            
            Text(String(localized: "Unlock Full Potential"))
                .font(.system(size: 26, weight: .heavy))
//                .foregroundStyle(MMColor.text)
                .multilineTextAlignment(.center)
            
            Text(String(localized: "Get intelligent AI and many features."))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {

        VStack(spacing: 12) {

            ForEach(featureItems) { item in
                featureRow(
                    item: item,
                    )
            }
        }
        .padding(16)
//        .background(MMColor.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary, lineWidth: 1)
        )
    }
    
    private func featureRow(item: FeatureItem) -> some View {
        HStack(alignment: .top, spacing: 14) {

            Image(systemName: item.icon)
            .font(.system(size: 18, weight: .semibold))
//            .foregroundStyle(MMColor.accent)
            .frame(width: 28, height: 28)
//            .background(MMColor.accentGlow)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )

            VStack(alignment: .leading, spacing: 3) {

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(MMColor.text)

                Text(item.subtitle)
                    .font(.system(size: 12))
//                    .foregroundStyleMMColor.muted2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
//            .foregroundStyle(MMColor.accent)
        }
    }
    
    // MARK: - Plans
    
    private var plansSection: some View {
        Group {
            if viewModel.isProductLoading && viewModel.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    //                        .tint(MMColor.accent)

                    Text(String(localized: "Loading plans..."))
                        .font(.system(size: 13, weight: .medium))
                    //                        .foregroundStyle(MMColor.muted2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if let productLoadErrorMessage {
                VStack(spacing: 10) {
                    Text(String(localized: "Error"))
                        .font(.system(size: 18, weight: .heavy))
                    //                        .foregroundStyle(MMColor.text)

                    Text(productLoadErrorMessage)
                        .font(.system(size: 13))
                    //                        .foregroundStyle(MMColor.muted2)
                        .multilineTextAlignment(.center)

                    Button(String(localized: "Retry")) {
                        Task {
                            await fetchProducts()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    //                    .foregroundStyle(MMColor.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                //                .background(MMColor.surface)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary, lineWidth: 1)
                )
            } else {
                VStack(spacing: 30) {
                    ForEach(viewModel.products, id: \.self) { product in
                        planCard(product: product)
                    }

                    if let currentPlan = viewModel.products.first(where: { $0.status == .active })?.snapshot,
                       let renewalInfo = currentPlan.renewalInfo?.info {
                        planStatus(currentPlan: currentPlan, renewalInfo: renewalInfo)
                    }
                }
            }
        }
    }

    private func planCard(product: ProductInfo) -> some View {
        
        let isSelected = selectedProductId == product.id

        let isActive = product.isActive == true
        let isNonConsumable = product.type == .nonConsumable
        let introductoryOffer = product.subscription?.introductoryOffer

        let hasEligibleIntroductoryOffer = product.shouldDisplayIntroductoryOffer && !isActive

        return Button {
            
            guard !viewModel.isProductPurchasing else {
                return
            }
            
            selectedProductId = product.id

        } label: {
            
            VStack(alignment: .leading, spacing: 5) {
                
                HStack(spacing: 14) {
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.blue : Color.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack(spacing: 8) {
                            
                            Text(product.displayName)
                                .font(.system(size: 16, weight: .heavy))
//                                .foregroundStyle(MMColor.text)
                            
                            if isActive {
                                
                                Text(String(localized: isNonConsumable ? "UNLOCKED" : "ACTIVE"))
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(product.description)
                            .font(.system(size: 11))
//                            .foregroundStyle(MMColor.muted)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {

                        if hasEligibleIntroductoryOffer, let introductoryOffer {
                            introPriceColumn(
                                product: product,
                                offer: introductoryOffer,
                                isSelected: isSelected
                            )
                        } else {
                            regularPriceColumn(product: product, isSelected: isSelected)
                        }
                    }
                }
                .padding(16)
                .foregroundStyle(isSelected ? Color.blue : Color.black)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.black,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func planStatus(currentPlan: ProductStatus, renewalInfo: RenewalStatus.Info) -> some View {
        let dateString = renewalInfo.date?.formatted(.dateTime.hour().minute().month().day().year()) ?? ""

        return VStack(spacing: 4) {
            switch currentPlan.type {
            case .autoRenewable:
                switch currentPlan.status {
                case .active, .upcoming:
                    if renewalInfo.currentProductID == renewalInfo.nextProductID {
                        Text("'\(currentPlan.displayName)' Renews Automatically")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.green)
                        Text("Your subscription will renew on \(dateString)")
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                    } else if let nextProductID = renewalInfo.nextProductID, renewalInfo.currentProductID != nextProductID {
                        let nextPlanName = PurchaseStatusManager.shared.snapshot(for: nextProductID)?.displayName ?? nextProductID
                        Text("Upcoming Plan Change")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.blue)
                        Text("Starting \(dateString), your plan will change from '\(currentPlan.displayName)' to '\(nextPlanName)'")
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("'\(currentPlan.displayName)' Subscription Cancelled")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.orange)
                        Text("Your subscription will remain active until \(dateString)")
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                    }
                case .inactive, .unlocked:
                    EmptyView()
                case .gracePeriod:
                    Text("Payment Issue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange)
                    Text("We couldn't process your payment. Your '\(currentPlan.displayName)' subscription remains active until \(dateString). Please update your payment method to avoid losing access.")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                case .billingRetryPeriod:
                    Text("Payment Issue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                    Text("We couldn't process your payment for your '\(currentPlan.displayName)' subscription. Apple is retrying the payment. Please update your payment method to restore your subscription.")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            case .nonRenewable:
                Text("'\(currentPlan.displayName)' Active")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.green)
                Text("Your subscription will remain active until \(dateString)")
                    .foregroundStyle(.secondary)
            case .consumable, .nonConsumable:
                EmptyView()
            default:
                EmptyView()
            }
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private func compactPrice(_ price: String) -> String {
        price.replacingOccurrences(of: ".00", with: "")
    }

    @ViewBuilder
    private func regularPriceColumn(product: ProductInfo, isSelected: Bool) -> some View {
        Text(compactPrice(product.displayPrice))
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(isSelected ? Color.blue : Color.black)
        if let period = product.subscriptionPeriodDescription {
            Text(period)
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.blue : Color.black)
        }
    }

    @ViewBuilder
    private func introPriceColumn(
        product: ProductInfo,
        offer: ProductInfo.SubscriptionOffer,
        isSelected: Bool
    ) -> some View {
        let cadence = product.subscriptionPeriodDescription
        let duration = offer.durationDescription
        let heroColor = isSelected ? Color.blue : Color.black

        VStack(alignment: .trailing, spacing: 3) {
            switch offer.paymentMode {
            case .payUpFront:
                Text(compactPrice(product.displayPrice))
                    .font(.system(size: 16))
                    .strikethrough()
                    .foregroundStyle(.secondary)

                if let equivalentPrice = product.comparableIntroDisplayPrice {
                    Text(compactPrice(equivalentPrice))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(heroColor)
                }
                if let cadence {
                    Text(cadence)
                        .font(.system(size: 10))
                        .foregroundStyle(heroColor)
                }
                Text("\(compactPrice(offer.displayPrice)) \(String(localized: "for first")) \(duration)")
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(heroColor)

            case .payAsYouGo:
                Text(compactPrice(product.displayPrice))
                    .font(.system(size: 16))
                    .strikethrough()
                    .foregroundStyle(.secondary)

                Text(compactPrice(product.comparableIntroDisplayPrice ?? offer.displayPrice))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(heroColor)
                if let cadence {
                    Text(cadence)
                        .font(.system(size: 10))
                        .foregroundStyle(heroColor)
                }
                Text("\(String(localized: "for first")) \(duration)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(heroColor)

            case .freeTrial:
                Text(compactPrice(product.displayPrice))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)

                if let cadence {
                    Text(cadence)
                        .font(.system(size: 10))
                        .foregroundStyle(heroColor)
                }
                Text("\(String(localized: "Free for first")) \(duration)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(heroColor)

            default:
                regularPriceColumn(product: product, isSelected: isSelected)
            }
        }
    }

    // MARK: - CTA
    
    private var ctaSection: some View {
        
        VStack(spacing: 8) {
            
            Button {
                subscribeAction()
            } label: {
                
                HStack(spacing: 8) {

                    if viewModel.isProductPurchasing {
                        ProgressView()
                    }

                    VStack(spacing: 2) {
                        Text(callToActionTitle)
                            .font(.system(size: 16, weight: .heavy))
                            .multilineTextAlignment(.center)

                        if let callToActionSubtitle {
                            Text(callToActionSubtitle)
                                .font(.system(size: 11, weight: .medium))
                                .opacity(0.85)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isProductPurchasing ? .gray : .blue)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }
            .disabled(
                viewModel.isProductPurchasing ||
                viewModel.isProductLoading &&
                viewModel.products.isEmpty
            )
            .buttonStyle(.plain)
        }
    }
    
    private var manageAndRestoreSection: some View {
        HStack(spacing: 8) {
            if viewModel.products.contains(where: { $0.type == .autoRenewable || $0.type == .nonRenewable }) {
                Button(String(localized: "Manage Subscription")) {
                    manageSubscriptionAction()
                }

                Text(" • ")
            }
            Button(String(localized: "Restore")) {
                restorePurchaseAction()
            }

            Text(" • ")

            Button(String(localized: "Redeem")) {
                redeemAction()
            }
        }
        .font(.system(size: 12, weight: .medium))
//        .foregroundStyle(MMColor.muted2)
    }
    
    // MARK: - Footer
    
    private var footerLinksSection: some View {
        HStack(spacing: 8) {

            Button(String(localized: "Terms & Conditions")) {
                termsAndConditionAction()
            }

            Text(" • ")

            Button(String(localized: "Privacy Policy")) {
                privacyPolicyAction()
            }
        }
        .font(.system(size: 12, weight: .medium))
//        .foregroundStyle(MMColor.muted2)
        .padding(.top, 8)
    }
}

extension PaywallView {

    // MARK: - Fetch Products
    
    private func fetchProducts() async {

        productLoadingErrorAlert.hide()
        productLoadErrorMessage = nil
        
        do {
            
            try await viewModel.fetchProducts(
                productIds: productIDs
            )
            
            if selectedProductId == nil {
                
                if let activeProduct =
                    viewModel.products.first(where: {$0.isActive}) {
                    
                    selectedProductId = activeProduct.id
                    
                } else {
                    selectedProductId = viewModel.products.first?.id
                }
            }
            
        } catch {
            
            productLoadingErrorAlert.show(
                title: String(localized: "Unable to Load Plans"), message: error.localizedDescription)
            productLoadErrorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Purchase
    
    private func subscribeAction() {
        
        guard let selectedProductId else {
            productPurchaseResultAlert.show(
                title: String(localized: "Select a Plan"),
                message: String(
                    localized: "Please select a subscription plan to continue."
                )
            )
            return
        }
        
        productPurchaseResultAlert.hide()
        
        if let product = viewModel.products.first(where: { $0.id == selectedProductId }),
           product.status != .inactive {
            showManageSubscription = true
        } else if let product = viewModel.products.first(where: { $0.id == selectedProductId }) {
            Task {
                let result = await viewModel.purchase(product: product)
                handlePurchaseResult(result, isRestore: false)
            }
        }
    }
    
    // MARK: - Manage Subscription
    
    private func manageSubscriptionAction() {
        guard !viewModel.isProductPurchasing else {
            return
        }
        
        showManageSubscription = true
    }
    
    // MARK: - Restore
    
    private func restorePurchaseAction() {
        guard !viewModel.isProductPurchasing else {
            return
        }
        
        productPurchaseResultAlert.hide()
        
        Task {
            
            let result = await viewModel.restorePurchases()
            
            handlePurchaseResult(result, isRestore: true)
        }
        
    }
    
    // MARK: - Redeem
    
    private func redeemAction() {
        guard !viewModel.isProductPurchasing else {
            return
        }

        viewModel.presentCodeRedemptionSheet()
    }

    
    // MARK: - Purchase Result
    
    private func handlePurchaseResult(_ result: PurchaseState, isRestore: Bool) {
        
        switch result {
        case .success:
            if isRestore {
                productPurchaseResultAlert.show(title: "Restored", message: "Purchase Restored completed successfully!")
            } else {
                productPurchaseResultAlert.show(title: "Success", message: "Purchase completed successfully!")
            }
        case .restored:
            productPurchaseResultAlert.show(title: "Restored", message: "Purchase Restored completed successfully!")
        case .pending:
            if isRestore {
                productPurchaseResultAlert.show(title: "Purchase Restored Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
            } else {
                productPurchaseResultAlert.show(title: "Purchase Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
            }

        case .userCancelled:
            break
            
        case .failure(let error):
            if isRestore {
                productPurchaseResultAlert.show(title: "Purchase Restoration Failed", message: error.localizedDescription)
            } else {
                productPurchaseResultAlert.show(title: "Purchase Failed", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Terms & Conditions
    
    private func termsAndConditionAction() {
        guard let url = URL(string: "https://www.google.com/") else {
            return
        }

        UIApplication.shared.open(url)
    }
    
    // MARK: - Privacy Policy
    
    private func privacyPolicyAction() {
        guard let url = URL(string: "https://www.google.com/") else {
            return
        }

        UIApplication.shared.open(url)
    }
    
    // MARK: - Close
    
    private func crossAction() {
        dismiss()
    }
}
