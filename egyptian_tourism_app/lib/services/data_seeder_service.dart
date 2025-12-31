import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to seed Firebase with initial dummy data
class DataSeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if data has already been seeded
  Future<bool> isDataSeeded() async {
    final doc =
        await _firestore.collection('app_settings').doc('seeder_status').get();
    return doc.exists && (doc.data()?['completed'] == true);
  }

  /// Seed all collections with dummy data
  Future<void> seedAllData() async {
    // Check if already seeded
    if (await isDataSeeded()) {
      print('Data already seeded. Skipping...');
      return;
    }

    print('Starting data seeding...');

    try {
      // Seed bazaars first (products reference them)
      await _seedBazaars();
      print('✓ Bazaars seeded');

      // Seed products
      await _seedProducts();
      print('✓ Products seeded');

      // Seed artifacts
      await _seedArtifacts();
      print('✓ Artifacts seeded');

      // Seed exhibition halls
      await _seedExhibitionHalls();
      print('✓ Exhibition halls seeded');

      // Seed visitor stories
      await _seedVisitorStories();
      print('✓ Visitor stories seeded');

      // Seed coupons
      await _seedCoupons();
      print('✓ Coupons seeded');

      // Seed sample reviews
      await _seedReviews();
      print('✓ Reviews seeded');

      // Mark as completed
      await _firestore.collection('app_settings').doc('seeder_status').set({
        'completed': true,
        'seededAt': FieldValue.serverTimestamp(),
      });

      print('✅ All data seeded successfully!');
    } catch (e) {
      print('❌ Error seeding data: $e');
      rethrow;
    }
  }

  /// Seed bazaars collection
  Future<void> _seedBazaars() async {
    final bazaars = [
      {
        'id': 'bazaar_1',
        'nameAr': 'بازار خان الخليلي',
        'nameEn': 'Khan El-Khalili Bazaar',
        'descriptionAr':
            'أشهر وأقدم أسواق القاهرة التاريخية، يعود تاريخه للقرن الرابع عشر. يضم مئات المحلات التي تبيع الحرف اليدوية والتحف والمجوهرات والتوابل.',
        'descriptionEn':
            'The most famous and oldest bazaar in historic Cairo, dating back to the 14th century.',
        'imageUrl':
            'https://images.unsplash.com/photo-1553913861-c0fddf2619ee?w=800',
        'galleryImages': [
          'https://images.unsplash.com/photo-1553913861-c0fddf2619ee?w=800',
          'https://images.unsplash.com/photo-1539768942893-daf53e448371?w=800',
        ],
        'address': 'شارع المعز لدين الله، الجمالية، القاهرة',
        'latitude': 30.0478,
        'longitude': 31.2620,
        'phone': '+20 2 25909764',
        'email': 'info@khankhalili.com',
        'ownerUserId': 'system',
        'productIds': ['product_1', 'product_2', 'product_3'],
        'isOpen': true,
        'workingHours': '10:00 - 23:00',
        'rating': 4.7,
        'reviewCount': 1250,
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': true,
      },
      {
        'id': 'bazaar_2',
        'nameAr': 'سوق أسوان',
        'nameEn': 'Aswan Souk',
        'descriptionAr':
            'سوق نوبي تقليدي يشتهر بالتوابل والعطور والمنسوجات النوبية الملونة والحرف اليدوية الأفريقية.',
        'descriptionEn':
            'Traditional Nubian market famous for spices, perfumes, and colorful Nubian textiles.',
        'imageUrl':
            'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800',
        'galleryImages': [
          'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800',
        ],
        'address': 'شارع السوق، أسوان',
        'latitude': 24.0889,
        'longitude': 32.8998,
        'phone': '+20 97 2303090',
        'email': null,
        'ownerUserId': 'system',
        'productIds': ['product_4', 'product_5'],
        'isOpen': true,
        'workingHours': '09:00 - 22:00',
        'rating': 4.5,
        'reviewCount': 890,
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': true,
      },
      {
        'id': 'bazaar_3',
        'nameAr': 'سوق الجمعة',
        'nameEn': 'Friday Market',
        'descriptionAr':
            'أكبر سوق شعبي في القاهرة للتحف والأنتيكات والمقتنيات النادرة. يقام كل يوم جمعة.',
        'descriptionEn':
            'The largest flea market in Cairo for antiques and rare collectibles.',
        'imageUrl':
            'https://images.unsplash.com/photo-1590736969955-71cc94901144?w=800',
        'galleryImages': [],
        'address': 'السيدة عائشة، القاهرة',
        'latitude': 30.0294,
        'longitude': 31.2569,
        'phone': '+20 2 25123456',
        'email': null,
        'ownerUserId': 'system',
        'productIds': ['product_6', 'product_7'],
        'isOpen': true,
        'workingHours': '06:00 - 14:00 (الجمعة فقط)',
        'rating': 4.2,
        'reviewCount': 650,
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': false,
      },
      {
        'id': 'bazaar_4',
        'nameAr': 'بازار الأقصر',
        'nameEn': 'Luxor Bazaar',
        'descriptionAr':
            'سوق سياحي بجوار معبد الأقصر، متخصص في التماثيل الفرعونية والبردي المرسوم يدوياً.',
        'descriptionEn':
            'Tourist market near Luxor Temple, specializing in pharaonic statues and hand-painted papyrus.',
        'imageUrl':
            'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800',
        'galleryImages': [],
        'address': 'كورنيش النيل، الأقصر',
        'latitude': 25.6994,
        'longitude': 32.6421,
        'phone': '+20 95 2370990',
        'email': 'luxorbazaar@example.com',
        'ownerUserId': 'system',
        'productIds': ['product_8', 'product_9', 'product_10'],
        'isOpen': true,
        'workingHours': '08:00 - 21:00',
        'rating': 4.4,
        'reviewCount': 720,
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': true,
      },
      {
        'id': 'bazaar_5',
        'nameAr': 'معرض الفسطاط للحرف',
        'nameEn': 'Fustat Handicrafts Center',
        'descriptionAr':
            'مركز حكومي للحرف التقليدية يضم ورش عمل حية للخزف والنحاس والزجاج المعشق.',
        'descriptionEn':
            'Government center for traditional crafts with live workshops.',
        'imageUrl':
            'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?w=800',
        'galleryImages': [],
        'address': 'منطقة الفسطاط، مصر القديمة، القاهرة',
        'latitude': 30.0062,
        'longitude': 31.2341,
        'phone': '+20 2 25311690',
        'email': 'fustat@crafts.gov.eg',
        'ownerUserId': 'system',
        'productIds': ['product_11', 'product_12'],
        'isOpen': true,
        'workingHours': '09:00 - 17:00',
        'rating': 4.6,
        'reviewCount': 340,
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': true,
      },
    ];

    final batch = _firestore.batch();
    for (final bazaar in bazaars) {
      final docRef =
          _firestore.collection('bazaars').doc(bazaar['id'] as String);
      batch.set(docRef, bazaar);
    }
    await batch.commit();
  }

  /// Seed products collection
  Future<void> _seedProducts() async {
    final products = [
      {
        'id': 'product_1',
        'nameAr': 'تمثال أبو الهول الذهبي',
        'nameEn': 'Golden Sphinx Statue',
        'descriptionAr':
            'نسخة مصغرة من تمثال أبو الهول مصنوعة من الراتنج المطلي بالذهب. تحفة فنية تضيف لمسة فرعونية راقية لمنزلك.',
        'descriptionEn':
            'Miniature replica of the Sphinx made of gold-plated resin.',
        'price': 450.0,
        'oldPrice': 600.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1608328607618-a77e0d77946e?w=800',
        'galleryImages': [
          'https://images.unsplash.com/photo-1608328607618-a77e0d77946e?w=800',
        ],
        'sizes': ['صغير (10سم)', 'متوسط (20سم)', 'كبير (35سم)'],
        'weight': '500 جرام',
        'dimensions': '20 × 10 × 15 سم',
        'material': 'راتنج مطلي بالذهب',
        'category': 'تماثيل',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': false,
        'isFeatured': true,
        'rating': 4.8,
        'reviewCount': 156,
      },
      {
        'id': 'product_2',
        'nameAr': 'بردية فرعونية مرسومة يدوياً',
        'nameEn': 'Hand-painted Pharaonic Papyrus',
        'descriptionAr':
            'بردية أصلية مرسومة يدوياً بألوان طبيعية تصور مشهد من كتاب الموتى. تأتي مع شهادة أصالة.',
        'descriptionEn': 'Authentic papyrus hand-painted with natural colors.',
        'price': 280.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800',
        'galleryImages': [],
        'sizes': ['A4', 'A3', 'A2'],
        'weight': '50 جرام',
        'dimensions': '30 × 40 سم',
        'material': 'بردي طبيعي',
        'category': 'بردي',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': true,
        'isFeatured': true,
        'rating': 4.9,
        'reviewCount': 89,
      },
      {
        'id': 'product_3',
        'nameAr': 'علبة مجوهرات خشبية مطعمة',
        'nameEn': 'Inlaid Wooden Jewelry Box',
        'descriptionAr':
            'علبة مجوهرات مصنوعة يدوياً من خشب الجوز المصري ومطعمة بالصدف والعاج الصناعي بتصميم إسلامي.',
        'descriptionEn':
            'Handmade jewelry box from Egyptian walnut inlaid with shell patterns.',
        'price': 550.0,
        'oldPrice': 700.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
        'galleryImages': [],
        'sizes': ['صغير', 'وسط', 'كبير'],
        'weight': '800 جرام',
        'dimensions': '25 × 15 × 10 سم',
        'material': 'خشب جوز مطعم بالصدف',
        'category': 'خشبيات',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.6,
        'reviewCount': 67,
      },
      {
        'id': 'product_4',
        'nameAr': 'شال نوبي تقليدي',
        'nameEn': 'Traditional Nubian Shawl',
        'descriptionAr':
            'شال قطني منسوج يدوياً بألوان نوبية زاهية. مثالي كهدية أو للاستخدام اليومي.',
        'descriptionEn': 'Hand-woven cotton shawl in vibrant Nubian colors.',
        'price': 180.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=800',
        'galleryImages': [],
        'sizes': ['قياس موحد'],
        'weight': '200 جرام',
        'dimensions': '180 × 60 سم',
        'material': 'قطن 100%',
        'category': 'منسوجات',
        'bazaarId': 'bazaar_2',
        'bazaarName': 'سوق أسوان',
        'isNew': true,
        'isFeatured': true,
        'rating': 4.7,
        'reviewCount': 234,
      },
      {
        'id': 'product_5',
        'nameAr': 'مجموعة توابل أسوان',
        'nameEn': 'Aswan Spice Collection',
        'descriptionAr':
            'علبة هدايا تحتوي على 8 أنواع من التوابل والأعشاب الأسوانية الأصلية: كركديه، كركم، كمون، حبة البركة، وغيرها.',
        'descriptionEn':
            'Gift box with 8 types of authentic Aswan spices and herbs.',
        'price': 120.0,
        'oldPrice': 150.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=800',
        'galleryImages': [],
        'sizes': ['علبة صغيرة', 'علبة كبيرة'],
        'weight': '400 جرام',
        'dimensions': '20 × 20 × 5 سم',
        'material': 'توابل طبيعية',
        'category': 'توابل',
        'bazaarId': 'bazaar_2',
        'bazaarName': 'سوق أسوان',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.9,
        'reviewCount': 312,
      },
      {
        'id': 'product_6',
        'nameAr': 'ساعة جيب أثرية',
        'nameEn': 'Antique Pocket Watch',
        'descriptionAr':
            'ساعة جيب نحاسية من عهد الخديوي إسماعيل، قطعة نادرة للمقتنين.',
        'descriptionEn': 'Brass pocket watch from the Khedive Ismail era.',
        'price': 2500.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1509048191080-d2984bad6ae5?w=800',
        'galleryImages': [],
        'sizes': ['قطعة واحدة'],
        'weight': '150 جرام',
        'dimensions': '5 × 5 × 2 سم',
        'material': 'نحاس',
        'category': 'أنتيكات',
        'bazaarId': 'bazaar_3',
        'bazaarName': 'سوق الجمعة',
        'isNew': false,
        'isFeatured': true,
        'rating': 4.3,
        'reviewCount': 12,
      },
      {
        'id': 'product_7',
        'nameAr': 'جرامافون قديم',
        'nameEn': 'Vintage Gramophone',
        'descriptionAr':
            'جرامافون من الأربعينيات بحالة ممتازة، يعمل بشكل كامل. قطعة ديكور فريدة.',
        'descriptionEn':
            'Working gramophone from the 1940s in excellent condition.',
        'price': 8500.0,
        'oldPrice': 10000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        'galleryImages': [],
        'sizes': ['قطعة واحدة'],
        'weight': '5 كجم',
        'dimensions': '40 × 40 × 35 سم',
        'material': 'خشب ونحاس',
        'category': 'أنتيكات',
        'bazaarId': 'bazaar_3',
        'bazaarName': 'سوق الجمعة',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.8,
        'reviewCount': 5,
      },
      {
        'id': 'product_8',
        'nameAr': 'تمثال توت عنخ آمون',
        'nameEn': 'Tutankhamun Statue',
        'descriptionAr':
            'نسخة طبق الأصل من قناع الفرعون توت عنخ آمون، مصنوعة بدقة عالية من الجبس المطلي.',
        'descriptionEn': 'Accurate replica of King Tutankhamun\'s mask.',
        'price': 1200.0,
        'oldPrice': 1500.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1608328607613-b8b8c8f18101?w=800',
        'galleryImages': [],
        'sizes': ['نصف الحجم', 'الحجم الكامل'],
        'weight': '2 كجم',
        'dimensions': '30 × 20 × 20 سم',
        'material': 'جبس مطلي',
        'category': 'تماثيل',
        'bazaarId': 'bazaar_4',
        'bazaarName': 'بازار الأقصر',
        'isNew': false,
        'isFeatured': true,
        'rating': 4.7,
        'reviewCount': 198,
      },
      {
        'id': 'product_9',
        'nameAr': 'خرطوش فرعوني باسمك',
        'nameEn': 'Personalized Pharaonic Cartouche',
        'descriptionAr':
            'خرطوش فضة أو ذهب محفور عليه اسمك بالهيروغليفية. هدية مميزة وشخصية.',
        'descriptionEn':
            'Silver or gold cartouche engraved with your name in hieroglyphics.',
        'price': 350.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
        'galleryImages': [],
        'sizes': ['فضة صغير', 'فضة كبير', 'ذهب صغير', 'ذهب كبير'],
        'weight': '15 جرام',
        'dimensions': '4 × 2 سم',
        'material': 'فضة 925 أو ذهب 18',
        'category': 'مجوهرات',
        'bazaarId': 'bazaar_4',
        'bazaarName': 'بازار الأقصر',
        'isNew': true,
        'isFeatured': false,
        'rating': 4.9,
        'reviewCount': 445,
      },
      {
        'id': 'product_10',
        'nameAr': 'لوحة زيتية - معبد الكرنك',
        'nameEn': 'Oil Painting - Karnak Temple',
        'descriptionAr':
            'لوحة زيتية مرسومة يدوياً لمعبد الكرنك عند غروب الشمس.',
        'descriptionEn':
            'Hand-painted oil painting of Karnak Temple at sunset.',
        'price': 800.0,
        'oldPrice': 950.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1578321272176-b7bbc0679853?w=800',
        'galleryImages': [],
        'sizes': ['40×60 سم', '60×90 سم', '80×120 سم'],
        'weight': '1.5 كجم',
        'dimensions': '60 × 90 سم',
        'material': 'زيت على قماش',
        'category': 'لوحات',
        'bazaarId': 'bazaar_4',
        'bazaarName': 'بازار الأقصر',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.6,
        'reviewCount': 78,
      },
      {
        'id': 'product_11',
        'nameAr': 'طقم شاي نحاسي مطعم',
        'nameEn': 'Inlaid Brass Tea Set',
        'descriptionAr':
            'طقم شاي نحاسي مكون من إبريق و6 أكواب، مطعم بالفضة بنقوش إسلامية.',
        'descriptionEn':
            'Brass tea set with teapot and 6 cups, silver-inlaid Islamic patterns.',
        'price': 1100.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        'galleryImages': [],
        'sizes': ['6 أشخاص', '12 شخص'],
        'weight': '3 كجم',
        'dimensions': '30 × 30 × 25 سم',
        'material': 'نحاس مطعم بالفضة',
        'category': 'نحاسيات',
        'bazaarId': 'bazaar_5',
        'bazaarName': 'معرض الفسطاط للحرف',
        'isNew': false,
        'isFeatured': true,
        'rating': 4.8,
        'reviewCount': 134,
      },
      {
        'id': 'product_12',
        'nameAr': 'فانوس رمضان تقليدي',
        'nameEn': 'Traditional Ramadan Lantern',
        'descriptionAr':
            'فانوس نحاسي مصنوع يدوياً بزجاج ملون، تصميم كلاسيكي مصري أصيل.',
        'descriptionEn':
            'Handmade brass lantern with colored glass, classic Egyptian design.',
        'price': 320.0,
        'oldPrice': 400.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1591825729269-caeb344f6df2?w=800',
        'galleryImages': [],
        'sizes': ['صغير (25سم)', 'وسط (40سم)', 'كبير (60سم)'],
        'weight': '1.2 كجم',
        'dimensions': '40 × 15 × 15 سم',
        'material': 'نحاس وزجاج ملون',
        'category': 'نحاسيات',
        'bazaarId': 'bazaar_5',
        'bazaarName': 'معرض الفسطاط للحرف',
        'isNew': true,
        'isFeatured': true,
        'rating': 4.9,
        'reviewCount': 267,
      },
      {
        'id': 'product_13',
        'nameAr': 'عقد فيروز سيناوي',
        'nameEn': 'Sinai Turquoise Necklace',
        'descriptionAr':
            'عقد من الفيروز السيناوي الأصلي مع خرز فضة. قطعة فريدة من التراث البدوي.',
        'descriptionEn':
            'Authentic Sinai turquoise necklace with silver beads.',
        'price': 650.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800',
        'galleryImages': [],
        'sizes': ['40 سم', '45 سم', '50 سم'],
        'weight': '80 جرام',
        'dimensions': '45 سم طول',
        'material': 'فيروز طبيعي وفضة',
        'category': 'مجوهرات',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.5,
        'reviewCount': 89,
      },
      {
        'id': 'product_14',
        'nameAr': 'سجادة صلاة مصرية',
        'nameEn': 'Egyptian Prayer Rug',
        'descriptionAr':
            'سجادة صلاة منسوجة يدوياً بتصميم المسجد الأزهر، خيوط قطنية فاخرة.',
        'descriptionEn': 'Hand-woven prayer rug with Al-Azhar Mosque design.',
        'price': 220.0,
        'oldPrice': 280.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1584286595398-a59c21c9a23e?w=800',
        'galleryImages': [],
        'sizes': ['قياس موحد'],
        'weight': '500 جرام',
        'dimensions': '120 × 70 سم',
        'material': 'قطن منسوج',
        'category': 'منسوجات',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': false,
        'isFeatured': false,
        'rating': 4.7,
        'reviewCount': 156,
      },
      {
        'id': 'product_15',
        'nameAr': 'عطر المسك الأبيض',
        'nameEn': 'White Musk Perfume',
        'descriptionAr':
            'عطر مسك أبيض أصلي بتركيز عالي، يدوم طويلاً. من أشهر عطور خان الخليلي.',
        'descriptionEn':
            'Authentic white musk perfume with high concentration.',
        'price': 95.0,
        'oldPrice': null,
        'imageUrl':
            'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=800',
        'galleryImages': [],
        'sizes': ['12 مل', '25 مل', '50 مل'],
        'weight': '100 جرام',
        'dimensions': '10 × 4 × 4 سم',
        'material': 'زيت عطري طبيعي',
        'category': 'عطور',
        'bazaarId': 'bazaar_1',
        'bazaarName': 'بازار خان الخليلي',
        'isNew': true,
        'isFeatured': false,
        'rating': 4.8,
        'reviewCount': 423,
      },
    ];

    final batch = _firestore.batch();
    for (final product in products) {
      final docRef =
          _firestore.collection('products').doc(product['id'] as String);
      batch.set(docRef, product);
    }
    await batch.commit();
  }

  /// Seed artifacts collection
  Future<void> _seedArtifacts() async {
    final artifacts = [
      {
        'id': 'artifact_1',
        'nameAr': 'قناع توت عنخ آمون الذهبي',
        'descriptionAr':
            'القناع الجنائزي الذهبي للفرعون توت عنخ آمون، أشهر قطعة أثرية في العالم. مصنوع من 11 كجم من الذهب الخالص.',
        'imageUrl':
            'https://images.unsplash.com/photo-1608328607618-a77e0d77946e?w=800',
        'era': 'الأسرة الثامنة عشر (1332-1323 ق.م)',
        'location': 'المتحف المصري الكبير',
        'isFeatured': true,
      },
      {
        'id': 'artifact_2',
        'nameAr': 'حجر رشيد',
        'descriptionAr':
            'الحجر الذي مكّن العلماء من فك رموز الكتابة الهيروغليفية. يحتوي على نص بثلاث لغات.',
        'imageUrl':
            'https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800',
        'era': 'العصر البطلمي (196 ق.م)',
        'location': 'المتحف البريطاني (نسخة بالمتحف المصري)',
        'isFeatured': true,
      },
      {
        'id': 'artifact_3',
        'nameAr': 'تمثال نفرتيتي',
        'descriptionAr':
            'التمثال النصفي للملكة نفرتيتي، يُعد من أجمل الأعمال الفنية في العالم القديم.',
        'imageUrl':
            'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=800',
        'era': 'الأسرة الثامنة عشر (1345 ق.م)',
        'location': 'متحف برلين الجديد (نسخة بالمتحف المصري)',
        'isFeatured': true,
      },
      {
        'id': 'artifact_4',
        'nameAr': 'مركب خوفو الشمسية',
        'descriptionAr':
            'مركب خشبية كاملة عُثر عليها مدفونة بجوار الهرم الأكبر. طولها 43 متراً.',
        'imageUrl':
            'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=800',
        'era': 'الأسرة الرابعة (2500 ق.م)',
        'location': 'المتحف المصري الكبير',
        'isFeatured': false,
      },
      {
        'id': 'artifact_5',
        'nameAr': 'تمثال أبو الهول',
        'descriptionAr':
            'أكبر تمثال منحوت من صخرة واحدة في العالم. يمثل جسم أسد ورأس إنسان.',
        'imageUrl':
            'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800',
        'era': 'الأسرة الرابعة (2500 ق.م)',
        'location': 'هضبة الأهرامات، الجيزة',
        'isFeatured': true,
      },
      {
        'id': 'artifact_6',
        'nameAr': 'كنوز تانيس الذهبية',
        'descriptionAr':
            'مجموعة من الأقنعة والحلي الذهبية لملوك الأسرة الحادية والعشرين.',
        'imageUrl':
            'https://images.unsplash.com/photo-1610550603070-a8c7e45b3b7a?w=800',
        'era': 'الأسرة الحادية والعشرين (1070-945 ق.م)',
        'location': 'المتحف المصري بالتحرير',
        'isFeatured': false,
      },
      {
        'id': 'artifact_7',
        'nameAr': 'كتاب الموتى',
        'descriptionAr':
            'مخطوطات بردية تحتوي على تعاويذ وأدعية كانت توضع مع الموتى لحمايتهم في العالم الآخر.',
        'imageUrl':
            'https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800',
        'era': 'الدولة الحديثة (1550-1070 ق.م)',
        'location': 'المتحف المصري الكبير',
        'isFeatured': false,
      },
      {
        'id': 'artifact_8',
        'nameAr': 'تمثال رمسيس الثاني',
        'descriptionAr':
            'تمثال ضخم للفرعون رمسيس الثاني يزن 83 طناً، كان في ميدان رمسيس.',
        'imageUrl':
            'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800',
        'era': 'الأسرة التاسعة عشر (1279-1213 ق.م)',
        'location': 'المتحف المصري الكبير',
        'isFeatured': true,
      },
      {
        'id': 'artifact_9',
        'nameAr': 'عجلة توت عنخ آمون الحربية',
        'descriptionAr':
            'عجلة حربية ذهبية كاملة مع زخارف دقيقة، اكتُشفت في مقبرة الفرعون.',
        'imageUrl':
            'https://images.unsplash.com/photo-1608328607618-a77e0d77946e?w=800',
        'era': 'الأسرة الثامنة عشر (1332-1323 ق.م)',
        'location': 'المتحف المصري الكبير',
        'isFeatured': false,
      },
      {
        'id': 'artifact_10',
        'nameAr': 'لوحة حمورابي المصرية',
        'descriptionAr':
            'لوحة حجرية تسجل معاهدة السلام بين رمسيس الثاني والحيثيين.',
        'imageUrl':
            'https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800',
        'era': 'الأسرة التاسعة عشر (1259 ق.م)',
        'location': 'معبد الكرنك، الأقصر',
        'isFeatured': false,
      },
    ];

    final batch = _firestore.batch();
    for (final artifact in artifacts) {
      final docRef =
          _firestore.collection('artifacts').doc(artifact['id'] as String);
      batch.set(docRef, artifact);
    }
    await batch.commit();
  }

  /// Seed exhibition halls collection
  Future<void> _seedExhibitionHalls() async {
    final halls = [
      {
        'id': 'hall_1',
        'nameAr': 'قاعة توت عنخ آمون',
        'imageUrl':
            'https://images.unsplash.com/photo-1608328607618-a77e0d77946e?w=800',
      },
      {
        'id': 'hall_2',
        'nameAr': 'قاعة المومياوات الملكية',
        'imageUrl':
            'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800',
      },
      {
        'id': 'hall_3',
        'nameAr': 'قاعة الكتابة والبردي',
        'imageUrl':
            'https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800',
      },
      {
        'id': 'hall_4',
        'nameAr': 'قاعة الدولة الحديثة',
        'imageUrl':
            'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800',
      },
      {
        'id': 'hall_5',
        'nameAr': 'قاعة الحلي والمجوهرات',
        'imageUrl':
            'https://images.unsplash.com/photo-1610550603070-a8c7e45b3b7a?w=800',
      },
    ];

    final batch = _firestore.batch();
    for (final hall in halls) {
      final docRef =
          _firestore.collection('exhibition_halls').doc(hall['id'] as String);
      batch.set(docRef, hall);
    }
    await batch.commit();
  }

  /// Seed visitor stories collection
  Future<void> _seedVisitorStories() async {
    final stories = [
      {
        'id': 'story_1',
        'imageUrl':
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
        'visitorName': 'أحمد محمود',
      },
      {
        'id': 'story_2',
        'imageUrl':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
        'visitorName': 'سارة خالد',
      },
      {
        'id': 'story_3',
        'imageUrl':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
        'visitorName': 'محمد علي',
      },
      {
        'id': 'story_4',
        'imageUrl':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
        'visitorName': 'فاطمة حسن',
      },
      {
        'id': 'story_5',
        'imageUrl':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
        'visitorName': 'عمر يوسف',
      },
    ];

    final batch = _firestore.batch();
    for (final story in stories) {
      final docRef =
          _firestore.collection('visitor_stories').doc(story['id'] as String);
      batch.set(docRef, story);
    }
    await batch.commit();
  }

  /// Seed coupons collection
  Future<void> _seedCoupons() async {
    final now = DateTime.now();
    final coupons = [
      {
        'id': 'coupon_1',
        'code': 'WELCOME10',
        'nameAr': 'خصم الترحيب',
        'descriptionAr': 'خصم 10% للمستخدمين الجدد على أول طلب',
        'type': 'percentage',
        'value': 10.0,
        'minOrderAmount': 100.0,
        'maxDiscount': 50.0,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 60)).toIso8601String(),
        'usageLimit': 1000,
        'usedCount': 0,
        'isActive': true,
      },
      {
        'id': 'coupon_2',
        'code': 'EGYPT20',
        'nameAr': 'خصم الحضارة',
        'descriptionAr': 'خصم 20% على جميع المنتجات الفرعونية',
        'type': 'percentage',
        'value': 20.0,
        'minOrderAmount': 200.0,
        'maxDiscount': 100.0,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 30)).toIso8601String(),
        'usageLimit': 500,
        'usedCount': 0,
        'isActive': true,
        'applicableCategoryIds': ['تماثيل', 'بردي'],
      },
      {
        'id': 'coupon_3',
        'code': 'FREESHIP',
        'nameAr': 'شحن مجاني',
        'descriptionAr': 'خصم 20 جنيه على الشحن',
        'type': 'fixed',
        'value': 20.0,
        'minOrderAmount': 150.0,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 90)).toIso8601String(),
        'usageLimit': null,
        'usedCount': 0,
        'isActive': true,
      },
      {
        'id': 'coupon_4',
        'code': 'BAZAAR50',
        'nameAr': 'خصم البازار الكبير',
        'descriptionAr': 'خصم ثابت 50 جنيه على الطلبات فوق 300 جنيه',
        'type': 'fixed',
        'value': 50.0,
        'minOrderAmount': 300.0,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 45)).toIso8601String(),
        'usageLimit': 200,
        'usedCount': 0,
        'isActive': true,
      },
    ];

    final batch = _firestore.batch();
    for (final coupon in coupons) {
      final docRef =
          _firestore.collection('coupons').doc(coupon['id'] as String);
      batch.set(docRef, coupon);
    }
    await batch.commit();
  }

  /// Seed reviews collection
  Future<void> _seedReviews() async {
    final now = DateTime.now();
    final reviews = [
      // Product reviews
      {
        'id': 'review_1',
        'userId': 'user_dummy_1',
        'userName': 'أحمد محمد',
        'userImageUrl': 'https://i.pravatar.cc/150?img=11',
        'targetId': 'product_1',
        'targetType': 'product',
        'rating': 5,
        'comment':
            'تمثال رائع جداً! الجودة ممتازة والتفاصيل دقيقة. أنصح بالشراء.',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'isVerifiedPurchase': true,
      },
      {
        'id': 'review_2',
        'userId': 'user_dummy_2',
        'userName': 'سارة خالد',
        'userImageUrl': 'https://i.pravatar.cc/150?img=5',
        'targetId': 'product_1',
        'targetType': 'product',
        'rating': 4,
        'comment': 'منتج جميل لكن الشحن تأخر قليلاً. التغليف كان ممتاز.',
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        'isVerifiedPurchase': true,
      },
      {
        'id': 'review_3',
        'userId': 'user_dummy_3',
        'userName': 'محمد علي',
        'userImageUrl': 'https://i.pravatar.cc/150?img=12',
        'targetId': 'product_2',
        'targetType': 'product',
        'rating': 5,
        'comment': 'البردية أصلية ورائعة! الألوان زاهية والرسم احترافي.',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'isVerifiedPurchase': true,
      },
      {
        'id': 'review_4',
        'userId': 'user_dummy_4',
        'userName': 'فاطمة حسن',
        'userImageUrl': 'https://i.pravatar.cc/150?img=9',
        'targetId': 'product_4',
        'targetType': 'product',
        'rating': 5,
        'comment': 'الشال النوبي جميل جداً! الألوان رائعة والقماش ناعم.',
        'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
        'isVerifiedPurchase': true,
      },
      // Bazaar reviews
      {
        'id': 'review_5',
        'userId': 'user_dummy_1',
        'userName': 'أحمد محمد',
        'userImageUrl': 'https://i.pravatar.cc/150?img=11',
        'targetId': 'bazaar_1',
        'targetType': 'bazaar',
        'rating': 5,
        'comment':
            'خان الخليلي مكان رائع! تنوع كبير في المنتجات والأسعار معقولة.',
        'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
        'isVerifiedPurchase': false,
      },
      {
        'id': 'review_6',
        'userId': 'user_dummy_5',
        'userName': 'عمر يوسف',
        'userImageUrl': 'https://i.pravatar.cc/150?img=13',
        'targetId': 'bazaar_2',
        'targetType': 'bazaar',
        'rating': 4,
        'comment': 'سوق أسوان جميل والتوابل طازجة. التعامل ممتاز مع الزبائن.',
        'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
        'isVerifiedPurchase': false,
      },
    ];

    final batch = _firestore.batch();
    for (final review in reviews) {
      final docRef =
          _firestore.collection('reviews').doc(review['id'] as String);
      batch.set(docRef, review);
    }
    await batch.commit();
  }

  /// Clear all seeded data (for testing)
  Future<void> clearAllData() async {
    final collections = [
      'products',
      'bazaars',
      'artifacts',
      'exhibition_halls',
      'visitor_stories',
      'coupons',
      'reviews',
      'app_settings'
    ];

    for (final collection in collections) {
      final docs = await _firestore.collection(collection).get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    print('All data cleared!');
  }
}
