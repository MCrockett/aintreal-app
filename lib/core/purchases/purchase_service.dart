import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ad_service.dart';

/// Service for managing in-app purchases.
///
/// Currently supports:
/// - Ad removal ($2.99 one-time purchase)
class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  /// Product ID for ad removal - must match App Store Connect / Google Play Console
  static const adRemovalProductId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;

  /// Whether IAP is available on this device.
  bool get isAvailable => _isAvailable;

  /// Record non-fatal error to Crashlytics.
  void _recordError(dynamic error, StackTrace? stack, String reason) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
    }
  }

  /// Whether a purchase is currently pending.
  bool get isPurchasePending => _purchasePending;

  /// Get the ad removal product if available.
  ProductDetails? get adRemovalProduct {
    try {
      return _products.firstWhere((p) => p.id == adRemovalProductId);
    } catch (_) {
      return null;
    }
  }

  /// Initialize the purchase service.
  Future<void> init() async {
    if (kIsWeb) return;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('PurchaseService: IAP not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('PurchaseService error: $error');
        _recordError(error, null, 'Purchase stream error');
      },
    );

    // Load products
    await _loadProducts();

    // Restore purchases to check if user already purchased ad removal
    await restorePurchases();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({adRemovalProductId});

    if (response.error != null) {
      debugPrint('PurchaseService: Error loading products: ${response.error}');
      _recordError(
        Exception(response.error!.message),
        null,
        'Failed to load IAP products',
      );
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          'PurchaseService: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('PurchaseService: Loaded ${_products.length} products');
    for (final product in _products) {
      debugPrint('  - ${product.id}: ${product.price}');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint(
          'PurchaseService: Purchase update - ${purchase.productID}: ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasePending = false;
          _handleSuccessfulPurchase(purchase);
          break;

        case PurchaseStatus.error:
          _purchasePending = false;
          debugPrint('PurchaseService: Purchase error: ${purchase.error}');
          _recordError(
            Exception(purchase.error?.message ?? 'Unknown purchase error'),
            null,
            'Purchase failed: ${purchase.productID}',
          );
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          debugPrint('PurchaseService: Purchase canceled');
          break;
      }

      // Complete purchase to acknowledge it
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    if (purchase.productID == adRemovalProductId) {
      debugPrint('PurchaseService: Ad removal purchased!');
      // Update AdService to disable ads
      AdService.instance.setAdRemovalPurchased(true);
    }
  }

  /// Purchase ad removal.
  /// Returns true if purchase was initiated, false if not available.
  Future<bool> purchaseAdRemoval() async {
    final product = adRemovalProduct;
    if (product == null) {
      debugPrint('PurchaseService: Ad removal product not available');
      return false;
    }

    debugPrint('PurchaseService: Initiating ad removal purchase');

    final purchaseParam = PurchaseParam(productDetails: product);

    // Ad removal is a non-consumable (one-time purchase)
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases.
  /// Call this on app startup and when user taps "Restore Purchases".
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    debugPrint('PurchaseService: Restoring purchases...');
    await _iap.restorePurchases();
  }

  /// Get the formatted price for ad removal.
  String? get adRemovalPrice => adRemovalProduct?.price;

  /// Dispose of the purchase service.
  void dispose() {
    _subscription?.cancel();
  }
}
