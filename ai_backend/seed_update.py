"""
🌱 Firestore Update — تحديث صور المنتجات + إضافة منتجات جديدة
نفّذ بـ: python seed_update.py
"""
import firebase_admin
from firebase_admin import credentials, firestore

def run():
    if not firebase_admin._apps:
        cred = credentials.Certificate("service_account.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    # === تحديث صور المنتجات الحالية ===
    print("🖼️ جاري تحديث صور المنتجات الحالية...")

    gallery_updates = {
        "product_1": {  # توت عنخ آمون
            "imageUrl": "https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800",
                "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
                "https://images.unsplash.com/photo-1560461396-ec0ef7bb29dd?w=800",
                "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800",
            ],
        },
        "product_2": {  # نفرتيتي
            "imageUrl": "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
                "https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800",
                "https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800",
            ],
        },
        "product_3": {  # أبو الهول
            "imageUrl": "https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800",
                "https://images.unsplash.com/photo-1568322503122-d3e54e29e113?w=800",
                "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800",
            ],
        },
        "product_4": {  # أنوبيس
            "imageUrl": "https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800",
                "https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800",
                "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
            ],
        },
        "product_5": {  # حورس
            "imageUrl": "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800",
                "https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800",
                "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
            ],
        },
        "product_6": {  # عقد عين حورس
            "imageUrl": "https://images.unsplash.com/photo-1515562141589-67f0d569b6b3?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1515562141589-67f0d569b6b3?w=800",
                "https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800",
                "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800",
                "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800",
            ],
        },
        "product_7": {  # أسورة فرعونية
            "imageUrl": "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800",
                "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800",
                "https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800",
            ],
        },
        "product_8": {  # فيروز سيناوي
            "imageUrl": "https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800",
                "https://images.unsplash.com/photo-1515562141589-67f0d569b6b3?w=800",
                "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800",
            ],
        },
        "product_9": {  # خاتم الجعران
            "imageUrl": "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800",
                "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800",
                "https://images.unsplash.com/photo-1515562141589-67f0d569b6b3?w=800",
            ],
        },
        "product_10": {  # بردي كتاب الموتى
            "imageUrl": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800",
                "https://images.unsplash.com/photo-1633164690057-e30e9b10f498?w=800",
                "https://images.unsplash.com/photo-1553913861-c0a802e63f49?w=800",
            ],
        },
        "product_11": {  # بردي خريطة
            "imageUrl": "https://images.unsplash.com/photo-1633164690057-e30e9b10f498?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1633164690057-e30e9b10f498?w=800",
                "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800",
                "https://images.unsplash.com/photo-1553913861-c0a802e63f49?w=800",
            ],
        },
        "product_12": {  # طقم شاي نحاسي
            "imageUrl": "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800",
                "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800",
                "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800",
            ],
        },
        "product_13": {  # إناء كانوبي
            "galleryImages": [
                "https://images.unsplash.com/photo-1590059390043-7567e4cacb09?w=800",
                "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800",
                "https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800",
            ],
        },
        "product_14": {  # خزف إسلامي
            "galleryImages": [
                "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800",
                "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800",
                "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800",
            ],
        },
        "product_15": {  # جلابية
            "galleryImages": [
                "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800",
                "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=800",
                "https://images.unsplash.com/photo-1521369909029-2afed882baee?w=800",
            ],
        },
        "product_16": {  # شال حريري
            "galleryImages": [
                "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=800",
                "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800",
            ],
        },
        "product_20": {  # قناع فرعوني
            "imageUrl": "https://images.unsplash.com/photo-1560461396-ec0ef7bb29dd?w=800",
            "galleryImages": [
                "https://images.unsplash.com/photo-1560461396-ec0ef7bb29dd?w=800",
                "https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800",
                "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800",
            ],
        },
        "product_22": {  # فانوس
            "galleryImages": [
                "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800",
                "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800",
                "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800",
            ],
        },
        "product_23": {  # زيوت عطرية
            "galleryImages": [
                "https://images.unsplash.com/photo-1547887538-e3a2f32cb1cc?w=800",
                "https://images.unsplash.com/photo-1602928321679-560bb453f190?w=800",
                "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800",
            ],
        },
        "product_29": {  # طقم فضة سيوي
            "galleryImages": [
                "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800",
                "https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800",
                "https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800",
                "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800",
            ],
        },
    }

    for pid, data in gallery_updates.items():
        db.collection("products").document(pid).update(data)
        print(f"  🖼️ {pid} — {len(data.get('galleryImages',[]))} صور")

    # === منتجات جديدة ===
    print("\n📦 جاري إضافة منتجات جديدة...")

    new_products = [
        {"id":"product_33","nameAr":"تمثال كليوباترا الملكي","nameEn":"Royal Cleopatra Statue","descriptionAr":"تمثال الملكة كليوباترا السابعة بالتاج الملكي والثعبان المقدس. منحوت من الرخام الأبيض مع تفاصيل مذهبة. آخر ملكات مصر القديمة.","descriptionEn":"White marble Cleopatra VII statue with royal crown and sacred serpent.","category":"تماثيل","material":"رخام أبيض مذهّب","dimensions":"15 × 10 × 35 سم","weight":"2 كجم","price":1100,"oldPrice":None,"rating":4.7,"reviewCount":123,"isFeatured":True,"isNew":True,"bazaarId":"bazaar_1","bazaarName":"بازار خان الخليلي","imageUrl":"https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800","galleryImages":["https://images.unsplash.com/photo-1562813733-b31f71025d54?w=800","https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800","https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800"],"sizes":["وسط 25سم","كبير 40سم"]},
        {"id":"product_34","nameAr":"تمثال باستت قطة فرعونية","nameEn":"Bastet Cat Goddess Statue","descriptionAr":"تمثال الإلهة باستت على هيئة قطة جالسة بزينة ذهبية. إلهة الحماية والمنزل عند المصريين القدماء. مصنوع من الراتنج الأسود اللامع.","descriptionEn":"Bastet cat goddess statue in black resin with gold adornments.","category":"تماثيل","material":"راتنج أسود لامع","dimensions":"10 × 8 × 22 سم","weight":"700 جرام","price":350,"oldPrice":420,"rating":4.6,"reviewCount":201,"isFeatured":False,"isNew":False,"bazaarId":"bazaar_2","bazaarName":"سوق الأقصر السياحي","imageUrl":"https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800","galleryImages":["https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800","https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800","https://images.unsplash.com/photo-1608326389673-56e60d213720?w=800"],"sizes":["صغير 15سم","وسط 22سم"]},
        {"id":"product_35","nameAr":"أقراط فرعونية ذهبية","nameEn":"Pharaonic Gold Earrings","descriptionAr":"أقراط مستوحاة من مجوهرات الملكة حتشبسوت. مطلية بالذهب عيار 18 مع نقوش اللوتس المصري. خفيفة ومريحة للاستخدام اليومي.","descriptionEn":"Hatshepsut-inspired earrings, 18K gold-plated with Egyptian lotus engravings.","category":"مجوهرات","material":"نحاس مطلي ذهب 18","dimensions":"طول 4 سم","weight":"12 جرام","price":280,"oldPrice":None,"rating":4.5,"reviewCount":178,"isFeatured":False,"isNew":True,"bazaarId":"bazaar_1","bazaarName":"بازار خان الخليلي","imageUrl":"https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800","galleryImages":["https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800","https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800","https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800"],"sizes":["مقاس واحد"]},
        {"id":"product_36","nameAr":"لوحة بردي - رحلة الآخرة","nameEn":"Papyrus - Journey to Afterlife","descriptionAr":"لوحة بردي تصور رحلة الروح في العالم الآخر حسب المعتقدات الفرعونية. مشهد المركب الشمسي مع الآلهة. ألوان يدوية طبيعية.","descriptionEn":"Papyrus depicting the soul's journey to the afterlife with the Solar Boat and deities.","category":"بردي","material":"ورق بردي طبيعي","dimensions":"70 × 50 سم","weight":"120 جرام","price":420,"oldPrice":480,"rating":4.8,"reviewCount":145,"isFeatured":True,"isNew":False,"bazaarId":"bazaar_4","bazaarName":"معرض الجيزة للتراث","imageUrl":"https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800","galleryImages":["https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800","https://images.unsplash.com/photo-1633164690057-e30e9b10f498?w=800","https://images.unsplash.com/photo-1553913861-c0a802e63f49?w=800"],"sizes":["50×35 سم","70×50 سم","100×70 سم"]},
        {"id":"product_37","nameAr":"مبخرة نحاسية مخرّمة","nameEn":"Pierced Brass Incense Burner","descriptionAr":"مبخرة نحاسية فاخرة بنقوش مخرّمة على الطراز المملوكي. تُعطي رائحة البخور مع إضاءة ساحرة عبر الفتحات. مع ملعقة نحاسية.","descriptionEn":"Mamluk-style pierced brass incense burner with copper spoon.","category":"نحاسيات","material":"نحاس أصفر مخرّم","dimensions":"12 × 12 × 18 سم","weight":"650 جرام","price":320,"oldPrice":None,"rating":4.6,"reviewCount":167,"isFeatured":False,"isNew":False,"bazaarId":"bazaar_5","bazaarName":"معرض الفسطاط للحرف","imageUrl":"https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800","galleryImages":["https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800","https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800","https://images.unsplash.com/photo-1602928321679-560bb453f190?w=800"],"sizes":["صغير 12سم","وسط 18سم"]},
        {"id":"product_38","nameAr":"وشاح نوبي ملون يدوي","nameEn":"Handwoven Nubian Shawl","descriptionAr":"وشاح نوبي تقليدي منسوج يدوياً بألوان زاهية تمثل رموز الحماية النوبية. قطن مصري 100% بأنامل حرفيات نوبيات.","descriptionEn":"Handwoven Nubian shawl with vibrant protective symbols, 100% Egyptian cotton.","category":"منسوجات","material":"قطن مصري","dimensions":"200 × 80 سم","weight":"250 جرام","price":280,"oldPrice":None,"rating":4.7,"reviewCount":89,"isFeatured":False,"isNew":True,"bazaarId":"bazaar_3","bazaarName":"بازار أسوان النوبي","imageUrl":"https://images.unsplash.com/photo-1600166898405-da9535204843?w=800","galleryImages":["https://images.unsplash.com/photo-1600166898405-da9535204843?w=800","https://images.unsplash.com/photo-1578898886225-c7c894047899?w=800","https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800"],"sizes":["150×60 سم","200×80 سم"]},
        {"id":"product_39","nameAr":"طقم فناجين قهوة عربية نحاسي","nameEn":"Brass Arabic Coffee Cup Set","descriptionAr":"طقم 6 فناجين قهوة عربية من النحاس المطعم بالفضة مع صينية دائرية. نقوش أرابيسك يدوية. الطقم المثالي للضيافة الشرقية.","descriptionEn":"6-piece brass Arabic coffee cup set with silver inlay and round tray.","category":"نحاسيات","material":"نحاس مطعم بالفضة","dimensions":"صينية 25سم قطر","weight":"1.5 كجم","price":750,"oldPrice":850,"rating":4.8,"reviewCount":112,"isFeatured":True,"isNew":False,"bazaarId":"bazaar_5","bazaarName":"معرض الفسطاط للحرف","imageUrl":"https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800","galleryImages":["https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=800","https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800","https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800"],"sizes":["4 فناجين","6 فناجين","12 فنجان"]},
        {"id":"product_40","nameAr":"عطر اللوتس المصري","nameEn":"Egyptian Lotus Perfume","descriptionAr":"عطر زيتي طبيعي برائحة زهرة اللوتس المصرية المقدسة. مستخلص بطريقة تقليدية بدون كحول. رائحة ناعمة وأنثوية. في زجاجة كريستال.","descriptionEn":"Natural oil-based Egyptian lotus perfume in crystal bottle, alcohol-free.","category":"عطور","material":"زيت عطري طبيعي","dimensions":"3 × 3 × 10 سم","weight":"60 جرام","price":220,"oldPrice":None,"rating":4.8,"reviewCount":289,"isFeatured":False,"isNew":True,"bazaarId":"bazaar_1","bazaarName":"بازار خان الخليلي","imageUrl":"https://images.unsplash.com/photo-1547887538-e3a2f32cb1cc?w=800","galleryImages":["https://images.unsplash.com/photo-1547887538-e3a2f32cb1cc?w=800","https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800","https://images.unsplash.com/photo-1602928321679-560bb453f190?w=800"],"sizes":["15 مل","30 مل","50 مل"]},
        {"id":"product_41","nameAr":"كتاب أساطير مصر القديمة","nameEn":"Myths of Ancient Egypt","descriptionAr":"كتاب مصور يروي أساطير الآلهة المصرية: إيزيس وأوزيريس، رع، ست وحورس. 280 صفحة بالعربية مع رسومات فنية ملونة.","descriptionEn":"Illustrated book of Egyptian mythology: Isis, Osiris, Ra, and Horus stories.","category":"كتب","material":"ورق مصقول فاخر","dimensions":"28 × 20 × 2.5 سم","weight":"900 جرام","price":195,"oldPrice":None,"rating":4.7,"reviewCount":156,"isFeatured":False,"isNew":False,"bazaarId":"bazaar_7","bazaarName":"سوق الإسكندرية التراثي","imageUrl":"https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800","galleryImages":["https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800","https://images.unsplash.com/photo-1524578271613-d550eacf6090?w=800"],"sizes":["غلاف عادي","غلاف فاخر"]},
        {"id":"product_42","nameAr":"محفظة جلدية بنقوش فرعونية","nameEn":"Pharaonic Leather Wallet","descriptionAr":"محفظة من الجلد الطبيعي المصري محفور عليها عين حورس والأنخ. بطانة من الجلد الناعم مع 8 جيوب للبطاقات وجيب للعملات.","descriptionEn":"Egyptian leather wallet with carved Eye of Horus and Ankh, 8 card slots.","category":"إكسسوارات","material":"جلد طبيعي مصري","dimensions":"12 × 10 × 2 سم","weight":"100 جرام","price":180,"oldPrice":220,"rating":4.4,"reviewCount":234,"isFeatured":False,"isNew":False,"bazaarId":"bazaar_6","bazaarName":"بازار شرم الشيخ","imageUrl":"https://images.unsplash.com/photo-1622396636133-8be631a73428?w=800","galleryImages":["https://images.unsplash.com/photo-1622396636133-8be631a73428?w=800","https://images.unsplash.com/photo-1597633425046-08f5110420b5?w=800","https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800"],"sizes":["رجالي","نسائي"]},
    ]

    for p in new_products:
        db.collection("products").document(p["id"]).set(p)
        print(f"  ✅ {p['nameAr']} — {p['category']}")

    print(f"\n🎉 تم تحديث صور {len(gallery_updates)} منتج + إضافة {len(new_products)} منتج جديد!")

if __name__ == "__main__":
    run()
