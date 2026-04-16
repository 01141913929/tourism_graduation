# خطة تنفيذية لنشر تطبيق السياحة للذكاء الاصطناعي (Tourist AI) على AWS

تم بناء هذه الخطة بناءً على دراستي العميقة لبنية النظام الخاص بك (Architecture) والأكواد الحالية. الهدف هو رفع الجزء الخاص بالسياحة (Tourist) ليعمل بكفاءة عالية وبدون تدخل يدوي منك.

## الأهداف
رفع الكود الخاص بـ `ai_backend` (تطبيق Tourist) إلى السيرفر الخاص بـ AWS. 
التأكد من التجميع (Docker Build) وربط الـ `API Gateway` (WebSocket) بقاعدة البيانات `Aurora Serverless` وكذلك `DynamoDB`.

## التغييرات المقترحة

### 1. تعديلات Terraform الخاصة بتطبيق السياحة
تم ملاحظة أن دالة الـ Lambda الخاصة بالـ Tourist Application (`ai_planner`) تشير بطريق الخطأ إلى صورة الإدارة (`admin_ai_repo`). سنقوم بإعادتها إلى مستودع السياحة الأساسي.

#### [MODIFY] [lambda.tf](file:///c:/Users/IT/.gemini/antigravity/scratch/ai_backend/terraform/lambda.tf)
- تغيير الـ `image_uri` ليقرأ من `ai_backend_repo` بدلاً من `admin_ai_repo` لضمان تشغيل `aws_websocket_handler.py`.

### 2. تفعيل البناء (Build) لتطبيق السياحة
كان السكربت الخاص بك مصممًا لتخطي بناء الـ Tourist مؤقتًا.

#### [MODIFY] [deploy.py](file:///c:/Users/IT/.gemini/antigravity/scratch/ai_backend/deploy.py)
- استبدال `if False:` إلى `if service in ["tourist", "all"]:` للبدء ببناء ملف الـ Docker المتخصصة في الـ WebSocket.
- في مرحلة تحديث الـ Lambda الإجبارية (Step 5.5)، سيتم إضافة أمر لتحديث دالة تطبيق السياحة (`egyptian-tourism-ai-planner-deployment-test`) بالصورة الجديدة.

## ⚠️ مراجعة المستخدم المطلوبة (User Review)
> [!IMPORTANT]
> - تنفيذ عملية النشر (**Deployment**) يتطلب تشغيل أوامر طرفية (Terminal Commands) باستخدام سكربت `deploy.py` الخاص بك للتواصل مع `AWS`. ذكرت "لا تنفذ الاوامر الترمينال الا للضرورة القصوى"، ولكن إنشاء الترفيع للبنية التحتية **هو ضرورة قصوى** للبدء بتقديم الخدمة على الحوسبة السحابية. سأستخدم الأوامر فقط لتشغيل الترفيع والتشييك ولا شيء غير ذلك.

## خطة التحقق (Verification Plan)
### اختبارات النشر والصلاحية:
بعد انتهاء السكربت من العمل، سأقوم بالتأكد من خلو رسائل الترفيع من أي خطأ خاص بـ `Terraform` أو `Docker`.

### التحقق من تكامل النظام:
سنجعل سكربت النشر يوفر بنجاح مسار `Tourist WebSocket URL` وسيرتبط بشكل سليم مع بيانات `DynamoDB` و `Aurora`.

**هل توافق على هذه الخطة للبدء بالتنفيذ الفوري والنشر على AWS؟**
