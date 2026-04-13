import 'package:flutter/foundation.dart';
import 'app_strings_ar.dart';
import 'app_strings_en.dart';

/// Centralized App Strings Manager
/// Provides access to localized strings based on current language
class AppStrings {
  static bool _isArabic = true;

  /// Set current language
  static void setLanguage(bool isArabic) {
    _isArabic = isArabic;
    debugPrint('🌍 Language set to: ${isArabic ? "Arabic" : "English"}');
  }

  /// Check if current language is Arabic
  static bool get isArabic => _isArabic;

  // ==================== GENERAL ====================
  static String get appName =>
      _isArabic ? AppStringsAr.appName : AppStringsEn.appName;
  static String get loading =>
      _isArabic ? AppStringsAr.loading : AppStringsEn.loading;
  static String get error =>
      _isArabic ? AppStringsAr.error : AppStringsEn.error;
  static String get retry =>
      _isArabic ? AppStringsAr.retry : AppStringsEn.retry;
  static String get cancel =>
      _isArabic ? AppStringsAr.cancel : AppStringsEn.cancel;
  static String get confirm =>
      _isArabic ? AppStringsAr.confirm : AppStringsEn.confirm;
  static String get save => _isArabic ? AppStringsAr.save : AppStringsEn.save;
  static String get delete =>
      _isArabic ? AppStringsAr.delete : AppStringsEn.delete;
  static String get edit => _isArabic ? AppStringsAr.edit : AppStringsEn.edit;
  static String get add => _isArabic ? AppStringsAr.add : AppStringsEn.add;
  static String get search =>
      _isArabic ? AppStringsAr.search : AppStringsEn.search;
  static String get filter =>
      _isArabic ? AppStringsAr.filter : AppStringsEn.filter;
  static String get sort => _isArabic ? AppStringsAr.sort : AppStringsEn.sort;
  static String get all => _isArabic ? AppStringsAr.all : AppStringsEn.all;
  static String get yes => _isArabic ? AppStringsAr.yes : AppStringsEn.yes;
  static String get no => _isArabic ? AppStringsAr.no : AppStringsEn.no;
  static String get ok => _isArabic ? AppStringsAr.ok : AppStringsEn.ok;
  static String get done => _isArabic ? AppStringsAr.done : AppStringsEn.done;
  static String get close =>
      _isArabic ? AppStringsAr.close : AppStringsEn.close;
  static String get back => _isArabic ? AppStringsAr.back : AppStringsEn.back;
  static String get next => _isArabic ? AppStringsAr.next : AppStringsEn.next;
  static String get previous =>
      _isArabic ? AppStringsAr.previous : AppStringsEn.previous;
  static String get seeAll =>
      _isArabic ? AppStringsAr.seeAll : AppStringsEn.seeAll;
  static String get noData =>
      _isArabic ? AppStringsAr.noData : AppStringsEn.noData;
  static String get noResults =>
      _isArabic ? AppStringsAr.noResults : AppStringsEn.noResults;
  static String get currency =>
      _isArabic ? AppStringsAr.currency : AppStringsEn.currency;

  // ==================== AUTH ====================
  static String get login =>
      _isArabic ? AppStringsAr.login : AppStringsEn.login;
  static String get logout =>
      _isArabic ? AppStringsAr.logout : AppStringsEn.logout;
  static String get register =>
      _isArabic ? AppStringsAr.register : AppStringsEn.register;
  static String get email =>
      _isArabic ? AppStringsAr.email : AppStringsEn.email;
  static String get password =>
      _isArabic ? AppStringsAr.password : AppStringsEn.password;
  static String get confirmPassword =>
      _isArabic ? AppStringsAr.confirmPassword : AppStringsEn.confirmPassword;
  static String get forgotPassword =>
      _isArabic ? AppStringsAr.forgotPassword : AppStringsEn.forgotPassword;
  static String get resetPassword =>
      _isArabic ? AppStringsAr.resetPassword : AppStringsEn.resetPassword;
  static String get fullName =>
      _isArabic ? AppStringsAr.fullName : AppStringsEn.fullName;
  static String get phoneNumber =>
      _isArabic ? AppStringsAr.phoneNumber : AppStringsEn.phoneNumber;
  static String get loginWithGoogle =>
      _isArabic ? AppStringsAr.loginWithGoogle : AppStringsEn.loginWithGoogle;
  static String get loginWithFacebook => _isArabic
      ? AppStringsAr.loginWithFacebook
      : AppStringsEn.loginWithFacebook;
  static String get orContinueWith =>
      _isArabic ? AppStringsAr.orContinueWith : AppStringsEn.orContinueWith;
  static String get dontHaveAccount =>
      _isArabic ? AppStringsAr.dontHaveAccount : AppStringsEn.dontHaveAccount;
  static String get alreadyHaveAccount => _isArabic
      ? AppStringsAr.alreadyHaveAccount
      : AppStringsEn.alreadyHaveAccount;
  static String get welcomeBack =>
      _isArabic ? AppStringsAr.welcomeBack : AppStringsEn.welcomeBack;
  static String get createAccount =>
      _isArabic ? AppStringsAr.createAccount : AppStringsEn.createAccount;
  static String get loginSuccess =>
      _isArabic ? AppStringsAr.loginSuccess : AppStringsEn.loginSuccess;
  static String get logoutConfirm =>
      _isArabic ? AppStringsAr.logoutConfirm : AppStringsEn.logoutConfirm;

  // ==================== NAVIGATION ====================
  static String get home => _isArabic ? AppStringsAr.home : AppStringsEn.home;
  static String get explore =>
      _isArabic ? AppStringsAr.explore : AppStringsEn.explore;
  static String get cart => _isArabic ? AppStringsAr.cart : AppStringsEn.cart;
  static String get orders =>
      _isArabic ? AppStringsAr.orders : AppStringsEn.orders;
  static String get profile =>
      _isArabic ? AppStringsAr.profile : AppStringsEn.profile;
  static String get settings =>
      _isArabic ? AppStringsAr.settings : AppStringsEn.settings;
  static String get favorites =>
      _isArabic ? AppStringsAr.favorites : AppStringsEn.favorites;
  static String get notifications =>
      _isArabic ? AppStringsAr.notifications : AppStringsEn.notifications;

  // ==================== HOME ====================
  static String get welcomeMessage =>
      _isArabic ? AppStringsAr.welcomeMessage : AppStringsEn.welcomeMessage;
  static String get featuredProducts =>
      _isArabic ? AppStringsAr.featuredProducts : AppStringsEn.featuredProducts;
  static String get categories =>
      _isArabic ? AppStringsAr.categories : AppStringsEn.categories;
  static String get popularBazaars =>
      _isArabic ? AppStringsAr.popularBazaars : AppStringsEn.popularBazaars;
  static String get newArrivals =>
      _isArabic ? AppStringsAr.newArrivals : AppStringsEn.newArrivals;
  static String get bestSellers =>
      _isArabic ? AppStringsAr.bestSellers : AppStringsEn.bestSellers;
  static String get specialOffers =>
      _isArabic ? AppStringsAr.specialOffers : AppStringsEn.specialOffers;

  // ==================== PRODUCTS ====================
  static String get products =>
      _isArabic ? AppStringsAr.products : AppStringsEn.products;
  static String get product =>
      _isArabic ? AppStringsAr.product : AppStringsEn.product;
  static String get productDetails =>
      _isArabic ? AppStringsAr.productDetails : AppStringsEn.productDetails;
  static String get price =>
      _isArabic ? AppStringsAr.price : AppStringsEn.price;
  static String get quantity =>
      _isArabic ? AppStringsAr.quantity : AppStringsEn.quantity;
  static String get size => _isArabic ? AppStringsAr.size : AppStringsEn.size;
  static String get color =>
      _isArabic ? AppStringsAr.color : AppStringsEn.color;
  static String get description =>
      _isArabic ? AppStringsAr.description : AppStringsEn.description;
  static String get specifications =>
      _isArabic ? AppStringsAr.specifications : AppStringsEn.specifications;
  static String get reviews =>
      _isArabic ? AppStringsAr.reviews : AppStringsEn.reviews;
  static String get addToCart =>
      _isArabic ? AppStringsAr.addToCart : AppStringsEn.addToCart;
  static String get buyNow =>
      _isArabic ? AppStringsAr.buyNow : AppStringsEn.buyNow;
  static String get outOfStock =>
      _isArabic ? AppStringsAr.outOfStock : AppStringsEn.outOfStock;
  static String get inStock =>
      _isArabic ? AppStringsAr.inStock : AppStringsEn.inStock;
  static String get selectSize =>
      _isArabic ? AppStringsAr.selectSize : AppStringsEn.selectSize;
  static String get selectColor =>
      _isArabic ? AppStringsAr.selectColor : AppStringsEn.selectColor;
  static String get addedToCart =>
      _isArabic ? AppStringsAr.addedToCart : AppStringsEn.addedToCart;
  static String get addedToFavorites =>
      _isArabic ? AppStringsAr.addedToFavorites : AppStringsEn.addedToFavorites;
  static String get removedFromFavorites => _isArabic
      ? AppStringsAr.removedFromFavorites
      : AppStringsEn.removedFromFavorites;

  // ==================== CART ====================
  static String get shoppingCart =>
      _isArabic ? AppStringsAr.shoppingCart : AppStringsEn.shoppingCart;
  static String get emptyCart =>
      _isArabic ? AppStringsAr.emptyCart : AppStringsEn.emptyCart;
  static String get emptyCartMessage =>
      _isArabic ? AppStringsAr.emptyCartMessage : AppStringsEn.emptyCartMessage;
  static String get startShopping =>
      _isArabic ? AppStringsAr.startShopping : AppStringsEn.startShopping;
  static String get subtotal =>
      _isArabic ? AppStringsAr.subtotal : AppStringsEn.subtotal;
  static String get shipping =>
      _isArabic ? AppStringsAr.shipping : AppStringsEn.shipping;
  static String get tax => _isArabic ? AppStringsAr.tax : AppStringsEn.tax;
  static String get discount =>
      _isArabic ? AppStringsAr.discount : AppStringsEn.discount;
  static String get total =>
      _isArabic ? AppStringsAr.total : AppStringsEn.total;
  static String get checkout =>
      _isArabic ? AppStringsAr.checkout : AppStringsEn.checkout;
  static String get applyCoupon =>
      _isArabic ? AppStringsAr.applyCoupon : AppStringsEn.applyCoupon;
  static String get enterCoupon =>
      _isArabic ? AppStringsAr.enterCoupon : AppStringsEn.enterCoupon;
  static String get couponApplied =>
      _isArabic ? AppStringsAr.couponApplied : AppStringsEn.couponApplied;
  static String get invalidCoupon =>
      _isArabic ? AppStringsAr.invalidCoupon : AppStringsEn.invalidCoupon;
  static String get removeItem =>
      _isArabic ? AppStringsAr.removeItem : AppStringsEn.removeItem;
  static String get clearCart =>
      _isArabic ? AppStringsAr.clearCart : AppStringsEn.clearCart;
  static String get updateQuantity =>
      _isArabic ? AppStringsAr.updateQuantity : AppStringsEn.updateQuantity;

  // ==================== CHECKOUT ====================
  static String get checkoutTitle =>
      _isArabic ? AppStringsAr.checkoutTitle : AppStringsEn.checkoutTitle;
  static String get deliveryAddress =>
      _isArabic ? AppStringsAr.deliveryAddress : AppStringsEn.deliveryAddress;
  static String get addAddress =>
      _isArabic ? AppStringsAr.addAddress : AppStringsEn.addAddress;
  static String get editAddress =>
      _isArabic ? AppStringsAr.editAddress : AppStringsEn.editAddress;
  static String get paymentMethod =>
      _isArabic ? AppStringsAr.paymentMethod : AppStringsEn.paymentMethod;
  static String get cashOnDelivery =>
      _isArabic ? AppStringsAr.cashOnDelivery : AppStringsEn.cashOnDelivery;
  static String get creditCard =>
      _isArabic ? AppStringsAr.creditCard : AppStringsEn.creditCard;
  static String get orderSummary =>
      _isArabic ? AppStringsAr.orderSummary : AppStringsEn.orderSummary;
  static String get placeOrder =>
      _isArabic ? AppStringsAr.placeOrder : AppStringsEn.placeOrder;
  static String get orderPlaced =>
      _isArabic ? AppStringsAr.orderPlaced : AppStringsEn.orderPlaced;
  static String get orderNumber =>
      _isArabic ? AppStringsAr.orderNumber : AppStringsEn.orderNumber;
  static String get trackOrder =>
      _isArabic ? AppStringsAr.trackOrder : AppStringsEn.trackOrder;
  static String get continueShopping =>
      _isArabic ? AppStringsAr.continueShopping : AppStringsEn.continueShopping;

  // ==================== ORDERS ====================
  static String get myOrders =>
      _isArabic ? AppStringsAr.myOrders : AppStringsEn.myOrders;
  static String get orderDetails =>
      _isArabic ? AppStringsAr.orderDetails : AppStringsEn.orderDetails;
  static String get orderStatus =>
      _isArabic ? AppStringsAr.orderStatus : AppStringsEn.orderStatus;
  static String get orderDate =>
      _isArabic ? AppStringsAr.orderDate : AppStringsEn.orderDate;
  static String get noOrders =>
      _isArabic ? AppStringsAr.noOrders : AppStringsEn.noOrders;
  static String get noOrdersMessage =>
      _isArabic ? AppStringsAr.noOrdersMessage : AppStringsEn.noOrdersMessage;

  // Order statuses
  static String get pending =>
      _isArabic ? AppStringsAr.pending : AppStringsEn.pending;
  static String get accepted =>
      _isArabic ? AppStringsAr.accepted : AppStringsEn.accepted;
  static String get preparing =>
      _isArabic ? AppStringsAr.preparing : AppStringsEn.preparing;
  static String get readyForPickup =>
      _isArabic ? AppStringsAr.readyForPickup : AppStringsEn.readyForPickup;
  static String get shipping2 =>
      _isArabic ? AppStringsAr.shipping2 : AppStringsEn.shipping2;
  static String get delivered =>
      _isArabic ? AppStringsAr.delivered : AppStringsEn.delivered;
  static String get cancelled =>
      _isArabic ? AppStringsAr.cancelled : AppStringsEn.cancelled;
  static String get rejected =>
      _isArabic ? AppStringsAr.rejected : AppStringsEn.rejected;

  // ==================== PROFILE ====================
  static String get myProfile =>
      _isArabic ? AppStringsAr.myProfile : AppStringsEn.myProfile;
  static String get editProfile =>
      _isArabic ? AppStringsAr.editProfile : AppStringsEn.editProfile;
  static String get personalInfo =>
      _isArabic ? AppStringsAr.personalInfo : AppStringsEn.personalInfo;
  static String get addresses =>
      _isArabic ? AppStringsAr.addresses : AppStringsEn.addresses;
  static String get paymentMethods =>
      _isArabic ? AppStringsAr.paymentMethods : AppStringsEn.paymentMethods;
  static String get orderHistory =>
      _isArabic ? AppStringsAr.orderHistory : AppStringsEn.orderHistory;
  static String get helpCenter =>
      _isArabic ? AppStringsAr.helpCenter : AppStringsEn.helpCenter;
  static String get aboutUs =>
      _isArabic ? AppStringsAr.aboutUs : AppStringsEn.aboutUs;
  static String get termsConditions =>
      _isArabic ? AppStringsAr.termsConditions : AppStringsEn.termsConditions;
  static String get privacyPolicy =>
      _isArabic ? AppStringsAr.privacyPolicy : AppStringsEn.privacyPolicy;
  static String get contactUs =>
      _isArabic ? AppStringsAr.contactUs : AppStringsEn.contactUs;
  static String get language =>
      _isArabic ? AppStringsAr.language : AppStringsEn.language;
  static String get arabic =>
      _isArabic ? AppStringsAr.arabic : AppStringsEn.arabic;
  static String get english =>
      _isArabic ? AppStringsAr.english : AppStringsEn.english;
  static String get darkMode =>
      _isArabic ? AppStringsAr.darkMode : AppStringsEn.darkMode;
  static String get notificationsSettings => _isArabic
      ? AppStringsAr.notificationsSettings
      : AppStringsEn.notificationsSettings;
  static String get deleteAccount =>
      _isArabic ? AppStringsAr.deleteAccount : AppStringsEn.deleteAccount;

  // ==================== SEARCH ====================
  static String get searchProducts =>
      _isArabic ? AppStringsAr.searchProducts : AppStringsEn.searchProducts;
  static String get searchBazaars =>
      _isArabic ? AppStringsAr.searchBazaars : AppStringsEn.searchBazaars;
  static String get recentSearches =>
      _isArabic ? AppStringsAr.recentSearches : AppStringsEn.recentSearches;
  static String get popularSearches =>
      _isArabic ? AppStringsAr.popularSearches : AppStringsEn.popularSearches;
  static String get noSearchResults =>
      _isArabic ? AppStringsAr.noSearchResults : AppStringsEn.noSearchResults;
  static String get tryDifferentKeywords => _isArabic
      ? AppStringsAr.tryDifferentKeywords
      : AppStringsEn.tryDifferentKeywords;

  // Filters
  static String get priceRange =>
      _isArabic ? AppStringsAr.priceRange : AppStringsEn.priceRange;
  static String get minPrice =>
      _isArabic ? AppStringsAr.minPrice : AppStringsEn.minPrice;
  static String get maxPrice =>
      _isArabic ? AppStringsAr.maxPrice : AppStringsEn.maxPrice;
  static String get rating =>
      _isArabic ? AppStringsAr.rating : AppStringsEn.rating;
  static String get category =>
      _isArabic ? AppStringsAr.category : AppStringsEn.category;
  static String get bazaar =>
      _isArabic ? AppStringsAr.bazaar : AppStringsEn.bazaar;
  static String get sortBy =>
      _isArabic ? AppStringsAr.sortBy : AppStringsEn.sortBy;
  static String get priceLowToHigh =>
      _isArabic ? AppStringsAr.priceLowToHigh : AppStringsEn.priceLowToHigh;
  static String get priceHighToLow =>
      _isArabic ? AppStringsAr.priceHighToLow : AppStringsEn.priceHighToLow;
  static String get newest =>
      _isArabic ? AppStringsAr.newest : AppStringsEn.newest;
  static String get topRated =>
      _isArabic ? AppStringsAr.topRated : AppStringsEn.topRated;
  static String get applyFilters =>
      _isArabic ? AppStringsAr.applyFilters : AppStringsEn.applyFilters;
  static String get clearFilters =>
      _isArabic ? AppStringsAr.clearFilters : AppStringsEn.clearFilters;

  // ==================== BAZAARS ====================
  static String get bazaars =>
      _isArabic ? AppStringsAr.bazaars : AppStringsEn.bazaars;
  static String get bazaarDetails =>
      _isArabic ? AppStringsAr.bazaarDetails : AppStringsEn.bazaarDetails;
  static String get bazaarProducts =>
      _isArabic ? AppStringsAr.bazaarProducts : AppStringsEn.bazaarProducts;
  static String get location =>
      _isArabic ? AppStringsAr.location : AppStringsEn.location;
  static String get openingHours =>
      _isArabic ? AppStringsAr.openingHours : AppStringsEn.openingHours;
  static String get viewOnMap =>
      _isArabic ? AppStringsAr.viewOnMap : AppStringsEn.viewOnMap;
  static String get callBazaar =>
      _isArabic ? AppStringsAr.callBazaar : AppStringsEn.callBazaar;
  static String get shareProduct =>
      _isArabic ? AppStringsAr.shareProduct : AppStringsEn.shareProduct;

  // ==================== REVIEWS ====================
  static String get writeReview =>
      _isArabic ? AppStringsAr.writeReview : AppStringsEn.writeReview;
  static String get yourRating =>
      _isArabic ? AppStringsAr.yourRating : AppStringsEn.yourRating;
  static String get yourReview =>
      _isArabic ? AppStringsAr.yourReview : AppStringsEn.yourReview;
  static String get submitReview =>
      _isArabic ? AppStringsAr.submitReview : AppStringsEn.submitReview;
  static String get reviewSubmitted =>
      _isArabic ? AppStringsAr.reviewSubmitted : AppStringsEn.reviewSubmitted;
  static String get basedOnReviews =>
      _isArabic ? AppStringsAr.basedOnReviews : AppStringsEn.basedOnReviews;

  // ==================== ERRORS ====================
  static String get networkError =>
      _isArabic ? AppStringsAr.networkError : AppStringsEn.networkError;
  static String get serverError =>
      _isArabic ? AppStringsAr.serverError : AppStringsEn.serverError;
  static String get unknownError =>
      _isArabic ? AppStringsAr.unknownError : AppStringsEn.unknownError;
  static String get sessionExpired =>
      _isArabic ? AppStringsAr.sessionExpired : AppStringsEn.sessionExpired;
  static String get invalidEmail =>
      _isArabic ? AppStringsAr.invalidEmail : AppStringsEn.invalidEmail;
  static String get weakPassword =>
      _isArabic ? AppStringsAr.weakPassword : AppStringsEn.weakPassword;
  static String get emailInUse =>
      _isArabic ? AppStringsAr.emailInUse : AppStringsEn.emailInUse;
  static String get wrongPassword =>
      _isArabic ? AppStringsAr.wrongPassword : AppStringsEn.wrongPassword;
  static String get userNotFound =>
      _isArabic ? AppStringsAr.userNotFound : AppStringsEn.userNotFound;
  static String get requiredField =>
      _isArabic ? AppStringsAr.requiredField : AppStringsEn.requiredField;

  // ==================== SUCCESS ====================
  static String get success =>
      _isArabic ? AppStringsAr.success : AppStringsEn.success;
  static String get saved =>
      _isArabic ? AppStringsAr.saved : AppStringsEn.saved;
  static String get updated =>
      _isArabic ? AppStringsAr.updated : AppStringsEn.updated;
  static String get deleted =>
      _isArabic ? AppStringsAr.deleted : AppStringsEn.deleted;
  static String get sentSuccessfully =>
      _isArabic ? AppStringsAr.sentSuccessfully : AppStringsEn.sentSuccessfully;

  // ==================== NOTIFICATIONS ====================
  static String get newOrder =>
      _isArabic ? AppStringsAr.newOrder : AppStringsEn.newOrder;
  static String get orderUpdated =>
      _isArabic ? AppStringsAr.orderUpdated : AppStringsEn.orderUpdated;
  static String get orderShipped =>
      _isArabic ? AppStringsAr.orderShipped : AppStringsEn.orderShipped;
  static String get orderDelivered =>
      _isArabic ? AppStringsAr.orderDelivered : AppStringsEn.orderDelivered;
  static String get specialOffer =>
      _isArabic ? AppStringsAr.specialOffer : AppStringsEn.specialOffer;
  static String get noNotifications =>
      _isArabic ? AppStringsAr.noNotifications : AppStringsEn.noNotifications;
  static String get markAllRead =>
      _isArabic ? AppStringsAr.markAllRead : AppStringsEn.markAllRead;

  // ==================== HELPER METHODS ====================

  /// Format price with currency
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} $currency';
  }

  /// Format count with label
  static String formatCount(int count, String singular, String plural) {
    if (_isArabic) {
      return '$count ${count == 1 ? singular : plural}';
    }
    return '$count ${count == 1 ? singular : plural}';
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (_isArabic) {
      if (hour < 12) return 'صباح الخير';
      if (hour < 17) return 'مساء الخير';
      return 'مساء الخير';
    } else {
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }
  }
}
