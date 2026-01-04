import Foundation

enum Language: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
    
    var name: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }
}

struct L10n {
    static func get(_ key: String, lang: String) -> String {
        let strings: [String: [String: String]] = [
            "en": [
                "welcome": "Welcome to SnapPack",
                "intro_desc": "The ultimate companion for your Snapchat Memories.",
                "feature1": "Secure local storage for your media",
                "feature2": "Lossless import from JSON exports",
                "feature3": "Chronological gallery organization",
                "get_started": "Get Started",
                "next": "Next",
                "skip": "Skip",
                "step1_title": "Step 1: Get Your Data",
                "step1_desc": "Open Snapchat settings and request your My Data export. Ensure you select the JSON format option when prompted.",
                "step2_title": "Step 2 & 3: Preparation",
                "step2_desc": "Snapchat will process your request (usually takes a day). Once ready, download the ZIP and extract the 'memories_history.json' file.",
                "step4_title": "Step 4, 5 & 6: Import",
                "step4_desc1": "Open the Downloader tab and select your JSON.",
                "step4_desc2": "Grant photo permissions to allow local saving.",
                "step4_desc3": "Enjoy your memories in the 'SC_Memories' album!",
                "gallery": "Gallery",
                "downloader": "Downloader",
                "settings": "Settings",
                "locker": "Locker",
                "no_media": "No Media Found",
                "select": "Select",
                "done": "Done",
                "cancel": "Cancel",
                "delete": "Delete",
                "share": "Share",
                "sort_by": "Sort By",
                "newest": "Newest",
                "oldest": "Oldest",
                "by_year": "By Year",
                "safe_private": "Safe & Private",
                "vault_secured": "Your encrypted vault is secured.",
                "enter_passcode": "Enter Passcode",
                "create_passcode": "Create Passcode",
                "set_passcode": "Set Vault Passcode",
                "save_passcode": "Save Passcode",
                "unlock": "Unlock",
                "ready_sync": "Ready to Sync?",
                "pick_json": "Tap below to pick your 'memories_history.json' file and begin the recovery process.",
                "select_file": "Select Media File",
                "storage_available": "Available Device Storage:",
                "pending": "Pending",
                "success": "Success",
                "failed": "Failed",
                "clean_up": "Clean Up Broken Files",
                "expired_link": "Expired link or Server Error",
                "start_download": "Start Download",
                "choose_another": "Choose Another File",
                "memories_ready": "Memories ready to sync",
                "features": "Features",
                "important_notes": "Important Notes",
                "disclaimer": "Disclaimer",
                "notes_desc": "• Download links expire 2 days after Snapchat prepares your data\n• Large libraries may take time to import\n• Keep the app open while downloading\n• Ensure you have sufficient iCloud/device storage",
                "features_desc": "• Save all photos and videos\n• Preserves original date metadata\n• Organized in SC_Memories album\n• Real-time progress tracking\n• Private and secure",
                "disclaimer_desc": "SnapPack is an independent utility and is not affiliated with, endorsed by, or sponsored by Snapchat or Snap Inc.",
                "choose_lang": "Choose Your Language",
                "lang_selected": "Language Selected",
                "photo": "Photo",
                "video": "Video"
            ],
            "ar": [
                "welcome": "مرحباً بك في SnapPack",
                "intro_desc": "الرفيق المثالي لذكرياتك في سناب شات.",
                "feature1": "تخزين محلي آمن لوسائطك",
                "feature2": "استيراد بدون فقدان الجودة من ملفات JSON",
                "feature3": "تنظيم زمني لمعرض الصور",
                "get_started": "ابدأ الآن",
                "next": "التالي",
                "skip": "تخطي",
                "step1_title": "الخطوة ١: احصل على بياناتك",
                "step1_desc": "افتح إعدادات سناب شات واطلب تصدير 'بياناتي'. تأكد من اختيار تنسيق JSON عند الطلب.",
                "step2_title": "الخطوة ٢ و ٣: التحضير",
                "step2_desc": "سيقوم سناب شات بمعالجة طلبك (يستغرق عادة يوماً واحداً). بمجرد الجاهزية، قم بتنزيل ملف ZIP واستخرج منه ملف 'memories_history.json'.",
                "step4_title": "الخطوة ٤ و ٥ و ٦: الاستيراد",
                "step4_desc1": "افتح علامة تبويب التنزيل واختر ملف JSON الخاص بك.",
                "step4_desc2": "امنح أذونات الصور للسماح بالحفظ المحلي.",
                "step4_desc3": "استمتع بذكرياتك في ألبوم 'SC_Memories'!",
                "gallery": "المعرض",
                "downloader": "أداة التنزيل",
                "settings": "الإعدادات",
                "locker": "الخزنة",
                "no_media": "لم يتم العثور على وسائط",
                "select": "تحديد",
                "done": "تم",
                "cancel": "إلغاء",
                "delete": "حذف",
                "share": "مشاركة",
                "sort_by": "فرز حسب",
                "newest": "الأحدث أولاً",
                "oldest": "الأقدم أولاً",
                "by_year": "حسب السنة",
                "safe_private": "آمن وخصوصي",
                "vault_secured": "خزنتك المشفرة مؤمنة.",
                "enter_passcode": "أدخل رمز المرور",
                "create_passcode": "إنشاء رمز مرور",
                "set_passcode": "تعيين رمز مرور الخزنة",
                "save_passcode": "حفظ رمز المرور",
                "unlock": "فتح",
                "ready_sync": "جاهز للمزامنة؟",
                "pick_json": "اضغط أدناه لاختيار ملف 'memories_history.json' وابدأ عملية الاسترداد.",
                "select_file": "اختر ملف الوسائط",
                "storage_available": "مساحة التخزين المتاحة:",
                "pending": "قيد الانتظار",
                "success": "ناجح",
                "failed": "فاشل",
                "clean_up": "تنظيف الملفات المعطوبة",
                "expired_link": "رابط منتهي الصلاحية أو خطأ بالمكتبة",
                "start_download": "ابدأ التنزيل",
                "choose_another": "اختر ملفاً آخر",
                "memories_ready": "ذكريات جاهزة للمزامنة",
                "features": "المميزات",
                "important_notes": "ملاحظات هامة",
                "disclaimer": "إخلاء مسؤولية",
                "notes_desc": "• تنتهي صلاحية روابط التنزيل بعد يومين من تحضير سناب شات لبياناتك\n• قد تستغرق المكتبات الكبيرة وقتاً للاستيراد\n• احتفظ بالتطبيق مفتوحاً أثناء التنزيل\n• تأكد من وجود مساحة تخزين كافية في iCloud أو الجهاز",
                "features_desc": "• حفظ جميع الصور ومقاطع الفيديو\n• الحفاظ على بيانات التاريخ الأصلية\n• منظمة في ألبوم SC_Memories\n• تتبع التقدم في الوقت الفعلي\n• خاص وآمن",
                "disclaimer_desc": "SnapPack هو أداة مستقلة ولا يتبع أو يتم اعتماده أو رعايته من قبل Snapchat أو Snap Inc.",
                "choose_lang": "اختر لغتك",
                "lang_selected": "تم اختيار اللغة",
                "photo": "صورة",
                "video": "فيديو"
            ]
        ]
        
        return strings[lang]?[key] ?? key
    }
}

extension String {
    func localized(_ lang: String) -> String {
        return L10n.get(self, lang: lang)
    }
}
