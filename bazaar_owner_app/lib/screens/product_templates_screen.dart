import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';

/// شاشة قوالب المنتجات الجاهزة
class ProductTemplatesScreen extends StatelessWidget {
  final Function(Map<String, dynamic> template) onSelectTemplate;

  const ProductTemplatesScreen({super.key, required this.onSelectTemplate});

  static final List<ProductTemplate> _templates = [
    // Jewelry
    ProductTemplate(
      category: 'مجوهرات',
      icon: Iconsax.diamonds,
      color: Colors.amber,
      products: [
        {
          'nameAr': 'قلادة فرعونية',
          'nameEn': 'Pharaonic Necklace',
          'descriptionAr':
              'قلادة فرعونية مصنوعة يدوياً بتصميم مستوحى من الحضارة المصرية القديمة',
          'category': 'مجوهرات',
          'sizes': ['صغير', 'وسط', 'كبير'],
          'material': 'نحاس مطلي ذهب',
        },
        {
          'nameAr': 'أسورة عين حورس',
          'nameEn': 'Eye of Horus Bracelet',
          'descriptionAr':
              'أسورة أنيقة بتصميم عين حورس الفرعونية للحماية والطاقة الإيجابية',
          'category': 'مجوهرات',
          'sizes': ['صغير', 'وسط', 'كبير'],
          'material': 'فضة 925',
        },
        {
          'nameAr': 'خاتم سكاراب',
          'nameEn': 'Scarab Ring',
          'descriptionAr':
              'خاتم مزخرف بتصميم الجعران الفرعوني رمز الحظ والتجدد',
          'category': 'مجوهرات',
          'sizes': ['16', '17', '18', '19', '20'],
          'material': 'نحاس عتيق',
        },
      ],
    ),
    // Clothing
    ProductTemplate(
      category: 'ملابس تقليدية',
      icon: Iconsax.lovely,
      color: Colors.purple,
      products: [
        {
          'nameAr': 'جلابية مصرية',
          'nameEn': 'Egyptian Galabeya',
          'descriptionAr':
              'جلابية قطنية تقليدية مريحة للارتداء اليومي أو المناسبات',
          'category': 'ملابس',
          'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
          'material': 'قطن 100%',
        },
        {
          'nameAr': 'عباءة نسائية',
          'nameEn': 'Ladies Abaya',
          'descriptionAr': 'عباءة أنيقة بتطريز يدوي وألوان جذابة',
          'category': 'ملابس',
          'sizes': ['S', 'M', 'L', 'XL'],
          'material': 'كريب',
        },
        {
          'nameAr': 'شال سيناوي',
          'nameEn': 'Sinai Shawl',
          'descriptionAr': 'شال تقليدي من سيناء بألوان زاهية وتطريز بدوي',
          'category': 'اكسسوارات',
          'sizes': ['حجم واحد'],
          'material': 'قطن وحرير',
        },
      ],
    ),
    // Handicrafts
    ProductTemplate(
      category: 'حرف يدوية',
      icon: Iconsax.rulerpen,
      color: Colors.teal,
      products: [
        {
          'nameAr': 'تمثال فرعوني',
          'nameEn': 'Pharaonic Statue',
          'descriptionAr': 'تمثال فرعوني منحوت يدوياً من الحجر المصري',
          'category': 'ديكور',
          'sizes': ['10 سم', '20 سم', '30 سم'],
          'material': 'حجر بازلت',
        },
        {
          'nameAr': 'صندوق خشبي مطعم',
          'nameEn': 'Inlaid Wooden Box',
          'descriptionAr': 'صندوق خشبي مطعم بالصدف والعظم بتصميم إسلامي',
          'category': 'ديكور',
          'sizes': ['صغير', 'وسط', 'كبير'],
          'material': 'خشب جوز',
        },
        {
          'nameAr': 'سجادة يدوية',
          'nameEn': 'Handmade Carpet',
          'descriptionAr': 'سجادة منسوجة يدوياً بنقوش تقليدية',
          'category': 'ديكور',
          'sizes': ['1x1.5م', '1.5x2م', '2x3م'],
          'material': 'صوف طبيعي',
        },
      ],
    ),
    // Souvenirs
    ProductTemplate(
      category: 'تذكارات',
      icon: Iconsax.gift,
      color: Colors.red,
      products: [
        {
          'nameAr': 'بردية مرسومة',
          'nameEn': 'Painted Papyrus',
          'descriptionAr': 'بردية مصرية مرسومة يدوياً برسوم فرعونية أصلية',
          'category': 'فنون',
          'sizes': ['A4', 'A3', 'A2'],
          'material': 'بردى طبيعي',
        },
        {
          'nameAr': 'ميدالية أهرامات',
          'nameEn': 'Pyramids Keychain',
          'descriptionAr': 'ميدالية مفاتيح على شكل أهرامات الجيزة',
          'category': 'اكسسوارات',
          'sizes': ['حجم واحد'],
          'material': 'معدن',
        },
        {
          'nameAr': 'مغناطيس سياحي',
          'nameEn': 'Tourist Magnet',
          'descriptionAr': 'مغناطيس ثلاجة بتصميم معالم مصرية',
          'category': 'تذكارات',
          'sizes': ['حجم واحد'],
          'material': 'بلاستيك وخشب',
        },
      ],
    ),
    // Food & Spices
    ProductTemplate(
      category: 'توابل وأطعمة',
      icon: Iconsax.blend_2,
      color: Colors.orange,
      products: [
        {
          'nameAr': 'دقة مصرية',
          'nameEn': 'Egyptian Dukkah',
          'descriptionAr': 'خليط توابل مصري تقليدي من المكسرات والبهارات',
          'category': 'توابل',
          'sizes': ['100 جم', '250 جم', '500 جم'],
          'material': null,
        },
        {
          'nameAr': 'كركديه فاخر',
          'nameEn': 'Premium Hibiscus',
          'descriptionAr': 'كركديه مصري طبيعي عالي الجودة',
          'category': 'مشروبات',
          'sizes': ['100 جم', '250 جم', '500 جم'],
          'material': null,
        },
        {
          'nameAr': 'عسل نحل صعيدي',
          'nameEn': 'Upper Egypt Honey',
          'descriptionAr': 'عسل نحل طبيعي من صعيد مصر',
          'category': 'أغذية',
          'sizes': ['250 جم', '500 جم', '1 كجم'],
          'material': null,
        },
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('قوالب المنتجات'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          return _buildCategorySection(context, _templates[index]);
        },
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, ProductTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: template.color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(template.icon, color: template.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${template.products.length} قالب',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products list
          ...template.products.map((product) => _buildProductTemplate(
                context,
                product,
                template.color,
              )),
        ],
      ),
    );
  }

  Widget _buildProductTemplate(
    BuildContext context,
    Map<String, dynamic> product,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        onSelectTemplate(product);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل قالب: ${product['nameAr']}'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['nameAr'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['descriptionAr'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildTag(product['category'], Colors.blue),
                      if (product['material'] != null)
                        _buildTag(product['material'], Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Iconsax.import_1, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class ProductTemplate {
  final String category;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> products;

  const ProductTemplate({
    required this.category,
    required this.icon,
    required this.color,
    required this.products,
  });
}
