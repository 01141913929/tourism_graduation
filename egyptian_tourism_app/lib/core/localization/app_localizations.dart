/// App Localizations - Translations for Arabic and English
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  bool get isArabic => languageCode == 'ar';

  // ===== Common =====
  String get appName => isArabic ? 'بازار' : 'Bazar';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get search => isArabic ? 'بحث' : 'Search';
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'تم بنجاح' : 'Success';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noData => isArabic ? 'لا توجد بيانات' : 'No data';
  String get seeAll => isArabic ? 'عرض الكل' : 'See All';

  // ===== Auth =====
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get signup => isArabic ? 'إنشاء حساب' : 'Sign Up';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get forgotPassword =>
      isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get name => isArabic ? 'الاسم' : 'Name';
  String get phone => isArabic ? 'رقم الهاتف' : 'Phone';

  // ===== Products =====
  String get products => isArabic ? 'المنتجات' : 'Products';
  String get product => isArabic ? 'منتج' : 'Product';
  String get price => isArabic ? 'السعر' : 'Price';
  String get category => isArabic ? 'التصنيف' : 'Category';
  String get description => isArabic ? 'الوصف' : 'Description';
  String get addToCart => isArabic ? 'أضف للسلة' : 'Add to Cart';
  String get buyNow => isArabic ? 'اشترِ الآن' : 'Buy Now';
  String get size => isArabic ? 'المقاس' : 'Size';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';
  String get inStock => isArabic ? 'متوفر' : 'In Stock';
  String get outOfStock => isArabic ? 'غير متوفر' : 'Out of Stock';
  String get newProduct => isArabic ? 'جديد' : 'New';
  String get featured => isArabic ? 'مميز' : 'Featured';
  String get discount => isArabic ? 'خصم' : 'Discount';

  // ===== Bazaar =====
  String get bazaars => isArabic ? 'البازارات' : 'Bazaars';
  String get bazaar => isArabic ? 'بازار' : 'Bazaar';
  String get open => isArabic ? 'مفتوح' : 'Open';
  String get closed => isArabic ? 'مغلق' : 'Closed';
  String get verified => isArabic ? 'موثق' : 'Verified';
  String get governorate => isArabic ? 'المحافظة' : 'Governorate';
  String get address => isArabic ? 'العنوان' : 'Address';

  // ===== Cart & Checkout =====
  String get myCart => isArabic ? 'سلة التسوق' : 'My Cart';
  String get checkout => isArabic ? 'إتمام الشراء' : 'Checkout';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get shipping => isArabic ? 'الشحن' : 'Shipping';
  String get taxes => isArabic ? 'الضرائب' : 'Taxes';
  String get total => isArabic ? 'الإجمالي' : 'Total';
  String get applyCoupon => isArabic ? 'تطبيق كوبون' : 'Apply Coupon';
  String get paymentMethod => isArabic ? 'طريقة الدفع' : 'Payment Method';
  String get shippingAddress => isArabic ? 'عنوان الشحن' : 'Shipping Address';
  String get placeOrder => isArabic ? 'تأكيد الطلب' : 'Place Order';
  String get cartEmpty => isArabic ? 'السلة فارغة' : 'Cart is empty';

  // ===== Orders =====
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get myOrders => isArabic ? 'طلباتي' : 'My Orders';
  String get orderDetails => isArabic ? 'تفاصيل الطلب' : 'Order Details';
  String get orderNumber => isArabic ? 'رقم الطلب' : 'Order #';
  String get orderDate => isArabic ? 'تاريخ الطلب' : 'Order Date';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get accepted => isArabic ? 'مقبول' : 'Accepted';
  String get preparing => isArabic ? 'جاري التحضير' : 'Preparing';
  String get shipped => isArabic ? 'تم الشحن' : 'Shipped';
  String get delivered => isArabic ? 'تم التوصيل' : 'Delivered';
  String get cancelled => isArabic ? 'ملغي' : 'Cancelled';
  String get trackOrder => isArabic ? 'تتبع الطلب' : 'Track Order';

  // ===== Reviews =====
  String get reviews => isArabic ? 'التقييمات' : 'Reviews';
  String get writeReview => isArabic ? 'اكتب تقييم' : 'Write Review';
  String get rating => isArabic ? 'التقييم' : 'Rating';

  // ===== Search =====
  String get searchProducts =>
      isArabic ? 'ابحث عن منتجات...' : 'Search products...';
  String get searchBazaars =>
      isArabic ? 'ابحث عن بازارات...' : 'Search bazaars...';
  String get recentSearches => isArabic ? 'بحث سابق' : 'Recent Searches';
  String get suggestions => isArabic ? 'اقتراحات' : 'Suggestions';
  String get noResults => isArabic ? 'لا توجد نتائج' : 'No results found';
  String get filters => isArabic ? 'الفلاتر' : 'Filters';
  String get applyFilters => isArabic ? 'تطبيق الفلاتر' : 'Apply Filters';
  String get clearAll => isArabic ? 'مسح الكل' : 'Clear All';
  String get priceRange => isArabic ? 'نطاق السعر' : 'Price Range';
  String get from => isArabic ? 'من' : 'From';
  String get to => isArabic ? 'إلى' : 'To';
  String get sortBy => isArabic ? 'ترتيب حسب' : 'Sort By';
  String get lowestPrice => isArabic ? 'الأقل سعراً' : 'Lowest Price';
  String get highestPrice => isArabic ? 'الأعلى سعراً' : 'Highest Price';
  String get newest => isArabic ? 'الأحدث' : 'Newest';
  String get highestRated => isArabic ? 'الأعلى تقييماً' : 'Highest Rated';

  // ===== Profile =====
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get personalInfo => isArabic ? 'المعلومات الشخصية' : 'Personal Info';
  String get myAddresses => isArabic ? 'عناويني' : 'My Addresses';
  String get paymentMethods => isArabic ? 'طرق الدفع' : 'Payment Methods';
  String get favorites => isArabic ? 'المفضلة' : 'Favorites';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get helpCenter => isArabic ? 'مركز المساعدة' : 'Help Center';
  String get aboutUs => isArabic ? 'عن التطبيق' : 'About Us';
  String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get termsConditions =>
      isArabic ? 'الشروط والأحكام' : 'Terms & Conditions';

  // ===== Messages =====
  String get messages => isArabic ? 'الرسائل' : 'Messages';
  String get sendMessage => isArabic ? 'إرسال رسالة' : 'Send Message';
  String get typeMessage =>
      isArabic ? 'اكتب رسالتك...' : 'Type your message...';
  String get noMessages => isArabic ? 'لا توجد رسائل' : 'No messages';

  // ===== Currency =====
  String currency(double amount) => isArabic
      ? '${amount.toStringAsFixed(0)} ج.م'
      : 'EGP ${amount.toStringAsFixed(0)}';

  // ===== Governorates =====
  String get cairo => isArabic ? 'القاهرة' : 'Cairo';
  String get giza => isArabic ? 'الجيزة' : 'Giza';
  String get luxor => isArabic ? 'الأقصر' : 'Luxor';
  String get aswan => isArabic ? 'أسوان' : 'Aswan';
  String get alexandria => isArabic ? 'الإسكندرية' : 'Alexandria';

  // ===== Categories =====
  String get all => isArabic ? 'الكل' : 'All';
  String get statues => isArabic ? 'تماثيل' : 'Statues';
  String get jewelry => isArabic ? 'مجوهرات' : 'Jewelry';
  String get traditionalClothes =>
      isArabic ? 'ملابس تقليدية' : 'Traditional Clothes';
  String get pottery => isArabic ? 'أواني' : 'Pottery';
  String get paintings => isArabic ? 'لوحات' : 'Paintings';
  String get souvenirs => isArabic ? 'هدايا تذكارية' : 'Souvenirs';
}
