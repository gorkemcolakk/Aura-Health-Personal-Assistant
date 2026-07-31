class TranslationService {
  static const Map<String, Map<String, String>> _translations = {
    // Settings
    'settings_title': {
      'tr': 'Uygulama Ayarları',
      'en': 'App Settings',
    },
    'settings_appearance': {
      'tr': 'Görünüm ve Dil',
      'en': 'Appearance & Language',
    },
    'settings_theme': {
      'tr': 'Tema Modu',
      'en': 'Theme Mode',
    },
    'settings_theme_sub': {
      'tr': 'Uygulamanın renk temasını belirleyin',
      'en': 'Choose app color theme',
    },
    'theme_light': {
      'tr': 'Açık',
      'en': 'Light',
    },
    'theme_dark': {
      'tr': 'Koyu',
      'en': 'Dark',
    },
    'theme_system': {
      'tr': 'Sistem',
      'en': 'System',
    },
    'settings_lang': {
      'tr': 'Dil',
      'en': 'Language',
    },
    'settings_lang_sub': {
      'tr': 'Arayüz ve yapay zeka dilini seçin',
      'en': 'Select interface and AI language',
    },
    'settings_data_privacy': {
      'tr': 'Veri ve Gizlilik',
      'en': 'Data & Privacy',
    },
    'settings_biometric': {
      'tr': 'Biyometrik Giriş',
      'en': 'Biometric Login',
    },
    'settings_biometric_sub': {
      'tr': 'Face ID veya parmak izi ile giriş yapın',
      'en': 'Login with Face ID or fingerprint',
    },
    'settings_reset': {
      'tr': 'Verileri Sıfırla',
      'en': 'Reset Data',
    },
    'settings_reset_sub': {
      'tr': 'Su, uyku ve ilaç kayıtlarınızı siler',
      'en': 'Deletes water, sleep and medication logs',
    },
    'prof_birth': {
      'tr': 'Doğum Tarihi',
      'en': 'Birth Date',
    },
    'dialog_reset_title': {
      'tr': 'Verileri Sıfırla',
      'en': 'Reset Data',
    },
    'dialog_reset_msg': {
      'tr': 'Su, uyku ve ilaç kayıtlarınız kalıcı olarak silinecektir. Bu işlem geri alınamaz. Onaylıyor musunuz?',
      'en': 'Your water, sleep and medication logs will be permanently deleted. This cannot be undone. Do you confirm?',
    },
    'btn_cancel': {
      'tr': 'İptal',
      'en': 'Cancel',
    },
    'btn_reset': {
      'tr': 'Sıfırla',
      'en': 'Reset',
    },
    'btn_save': {
      'tr': 'Kaydet',
      'en': 'Save',
    },
    'btn_close': {
      'tr': 'Kapat',
      'en': 'Close',
    },
    'msg_reset_success': {
      'tr': 'Verileriniz başarıyla sıfırlandı.',
      'en': 'Your data has been successfully reset.',
    },
    'msg_biometric_fail': {
      'tr': 'Biyometrik doğrulama kurulamadı.',
      'en': 'Biometric authentication could not be set up.',
    },
    'settings_notifications': {
      'tr': 'Bildirim Tercihleri',
      'en': 'Notification Preferences',
    },
    'settings_water_reminders': {
      'tr': 'Su Hatırlatıcıları',
      'en': 'Water Reminders',
    },
    'settings_meds_alarms': {
      'tr': 'İlaç Alarmları',
      'en': 'Medication Alarms',
    },
    'settings_weekly_report': {
      'tr': 'Haftalık Sağlık Raporu Bildirimi',
      'en': 'Weekly Health Report Notification',
    },
    'settings_account_mgmt': {
      'tr': 'Hesap Yönetimi',
      'en': 'Account Management',
    },
    'settings_change_password': {
      'tr': 'Şifre Değiştir',
      'en': 'Change Password',
    },
    'settings_change_password_sub': {
      'tr': 'Hesap şifrenizi güvenle güncelleyin',
      'en': 'Update your account password securely',
    },
    'settings_diagnostics': {
      'tr': 'Destek ve Tanılama',
      'en': 'Diagnostics & Support',
    },
    'settings_crash_reports': {
      'tr': 'Anonim kullanım ve çökme raporlarını paylaş',
      'en': 'Share anonymous usage and crash reports',
    },
    'settings_support_ticket': {
      'tr': 'Destek Talebi Oluştur',
      'en': 'Create Support Ticket',
    },
    'settings_support_ticket_sub': {
      'tr': 'Hata bildirimi yapın veya yardım isteyin',
      'en': 'Report a bug or ask for help',
    },
    'dialog_change_password_title': {
      'tr': 'Şifre Değiştir',
      'en': 'Change Password',
    },
    'dialog_support_title': {
      'tr': 'Destek Talebi',
      'en': 'Support Ticket',
    },
    'old_password': {
      'tr': 'Mevcut Şifre',
      'en': 'Current Password',
    },
    'new_password': {
      'tr': 'Yeni Şifre',
      'en': 'New Password',
    },
    'msg_password_changed': {
      'tr': 'Şifreniz başarıyla değiştirildi.',
      'en': 'Your password has been changed successfully.',
    },
    'msg_password_error': {
      'tr': 'Mevcut şifreniz hatalı. Lütfen tekrar deneyin.',
      'en': 'Current password is incorrect. Please try again.',
    },
    'msg_support_sent': {
      'tr': 'Destek talebiniz başarıyla gönderildi!',
      'en': 'Your support ticket has been sent successfully!',
    },

    // Bottom Nav
    'nav_today': {'tr': 'Bugün', 'en': 'Today'},
    'nav_charts': {'tr': 'Grafikler', 'en': 'Charts'},
    'nav_profile': {'tr': 'Profil', 'en': 'Profile'},
    'nav_meds': {'tr': 'İlaç', 'en': 'Meds'},
    'nav_ai': {'tr': 'AI', 'en': 'AI'},
    'nav_nearby': {'tr': 'Yakın Sağlık', 'en': 'Nearby'},
    'nav_quick': {'tr': 'Hızlı İşlemler', 'en': 'Quick Actions'},
    'quick_water': {'tr': 'Su Ekle', 'en': 'Add Water'},
    'quick_water_sub': {'tr': 'Günlük su tüketimine ekle', 'en': 'Add to daily water intake'},
    'quick_sleep': {'tr': 'Uyku Ekle', 'en': 'Add Sleep'},
    'quick_sleep_sub': {'tr': 'Bugünkü uyku kaydını ekle', 'en': 'Log today\'s sleep'},
    'quick_med': {'tr': 'İlaç Yönetimi', 'en': 'Medication'},
    'quick_med_sub': {'tr': 'İlaç ekle veya yönet', 'en': 'Add or manage medications'},
    'quick_nearby': {'tr': 'Yakın Sağlık Kuruluşları', 'en': 'Nearby Health Facilities'},
    'quick_nearby_sub': {'tr': 'Çevrendeki sağlık tesislerini bul', 'en': 'Find health facilities near you'},
    'quick_pdf': {'tr': 'Doktor Raporu', 'en': 'Doctor Report'},
    'quick_pdf_sub': {'tr': 'AI destekli PDF raporu oluştur', 'en': 'Generate AI-powered PDF report'},

    // Dashboard
    'dash_health_panel': {'tr': 'Sağlık Paneli', 'en': 'Health Panel'},
    'dash_water': {'tr': 'Su', 'en': 'Water'},
    'dash_bmi': {'tr': 'VKİ', 'en': 'BMI'},
    'dash_target': {'tr': 'Hedef', 'en': 'Target'},
    'dash_height': {'tr': 'Boy', 'en': 'Height'},
    'dash_weight': {'tr': 'Kilo', 'en': 'Weight'},
    'dash_water_track': {'tr': 'Su takibi', 'en': 'Water tracking'},
    'dash_custom_water': {'tr': 'Özel', 'en': 'Custom'},
    'dash_sleep_track': {'tr': 'Uyku takibi', 'en': 'Sleep tracking'},
    'dash_charts': {'tr': 'Grafiksel Sağlık Analizi', 'en': 'Graphical Health Analysis'},
    'dash_no_meds': {'tr': 'Bugün planlı ilaç yok', 'en': 'No planned medication today'},
    'dash_no_meds_sub': {'tr': 'İlaç sekmesinden günlük alarm ekleyebilirsin.', 'en': 'You can add daily alarms from the medication tab.'},
    'dash_insight': {'tr': 'Aura içgörüsü', 'en': 'Aura insight'},

    // Water Dialog
    'water_add_custom': {'tr': 'Özel Su Ekle', 'en': 'Add Custom Water'},
    'water_select_date': {'tr': 'Su içme tarihini seç', 'en': 'Select water intake date'},
    'water_manual_entry': {'tr': 'Manuel ml girişi', 'en': 'Manual ml entry'},
    
    // Sleep Dialog
    'sleep_add': {'tr': 'Uyku Ekle', 'en': 'Add Sleep'},
    'sleep_hours': {'tr': 'Kaç saat uyudun?', 'en': 'How many hours did you sleep?'},
    'sleep_feeling': {'tr': 'Nasıl hissediyorsun?', 'en': 'How do you feel?'},

    // Emergency
    'emerg_call': {'tr': '112 Acil', 'en': '911 Emergency'},
    'emerg_sos': {'tr': 'Acil Çağrı Gönder', 'en': 'Send SOS'},

    // Common
    'day_today': {'tr': 'Bugün', 'en': 'Today'},
    'day_yesterday': {'tr': 'Dün', 'en': 'Yesterday'},

    // Profile
    'prof_title': {'tr': 'Profil', 'en': 'Profile'},
    'prof_subtitle': {'tr': 'VKİ, su ihtiyacı ve AI önerileri bu bilgilerle hesaplanır.', 'en': 'BMI, water needs and AI suggestions are calculated with this.'},
    'prof_name': {'tr': 'Ad soyad', 'en': 'Full Name'},
    'prof_gender': {'tr': 'Cinsiyet', 'en': 'Gender'},
    'gender_male': {'tr': 'Erkek', 'en': 'Male'},
    'gender_female': {'tr': 'Kadın', 'en': 'Female'},
    'gender_unspecified': {'tr': 'Belirtilmedi', 'en': 'Unspecified'},
    'prof_age': {'tr': 'Yaş', 'en': 'Age'},
    'prof_activity': {'tr': 'Aktivite', 'en': 'Activity'},
    'prof_height': {'tr': 'Boy (cm)', 'en': 'Height (cm)'},
    'prof_weight': {'tr': 'Kilo (kg)', 'en': 'Weight (kg)'},
    'prof_water_target': {'tr': 'Günlük su hedefi', 'en': 'Daily water target'},
    'prof_sleep_target': {'tr': 'Günlük uyku hedefi', 'en': 'Daily sleep target'},
    'prof_goal': {'tr': 'Sağlık hedefi', 'en': 'Health goal'},
    'prof_conditions': {'tr': 'Notlar, hassasiyetler, tanılar', 'en': 'Notes, sensitivities, diagnosis'},
    'prof_emerg_info': {'tr': 'Acil Durum Bilgileri', 'en': 'Emergency Info'},
    'prof_blood': {'tr': 'Kan Grubu', 'en': 'Blood Type'},
    'prof_allergies': {'tr': 'Alerjiler', 'en': 'Allergies'},
    'prof_emerg_contact': {'tr': 'Acil Durumda Aranacak Kişi', 'en': 'Emergency Contact'},
    'prof_emerg_phone': {'tr': 'Acil Durum Telefonu', 'en': 'Emergency Phone'},
    'prof_save_msg': {'tr': 'Profil güncellendi', 'en': 'Profile updated'},
    'prof_bio_not_supported': {'tr': 'Cihazınızda biyometrik doğrulama desteği bulunamadı.', 'en': 'Biometrics not supported on this device.'},
    'prof_bio_on': {'tr': 'Biyometrik giriş aktif edildi', 'en': 'Biometrics enabled'},
    'prof_bio_off': {'tr': 'Biyometrik giriş kapatıldı', 'en': 'Biometrics disabled'},
    'prof_pdf': {'tr': 'Doktor Raporu Oluştur (PDF)', 'en': 'Generate Doctor Report (PDF)'},
    'prof_pdf_sub': {'tr': 'Yapay zeka destekli sağlık özeti', 'en': 'AI-powered health summary'},
    'prof_logout': {'tr': 'Hesaptan Çıkış Yap', 'en': 'Log Out'},

    // Medication
    'med_title': {'tr': 'İlaç Planı', 'en': 'Medication Plan'},
    'med_subtitle': {'tr': 'Günlük ilaç saatleri için yerel bildirim alarmı kurulur.', 'en': 'Local notification alarms are set for daily medication times.'},
    'med_name': {'tr': 'İlaç adı', 'en': 'Medication Name'},
    'med_dosage': {'tr': 'Doz', 'en': 'Dosage'},
    'med_notes': {'tr': 'Not', 'en': 'Notes'},
    'med_hour': {'tr': 'Saat', 'en': 'Time'},
    'med_meal_before': {'tr': 'Aç', 'en': 'Before Meal'},
    'med_meal_after': {'tr': 'Tok', 'en': 'After Meal'},
    'med_meal_any': {'tr': 'Fark etmez', 'en': 'Anytime'},
    'med_no_dosage': {'tr': 'Doz belirtilmedi', 'en': 'No dosage specified'},
    'med_add_success': {'tr': 'İlaç alarmı kuruldu', 'en': 'Medication alarm set'},
    'med_btn_add': {'tr': 'Alarm Ekle', 'en': 'Add Alarm'},
    'btn_delete': {'tr': 'Sil', 'en': 'Delete'},

    // Charts
    'chart_title': {'tr': '📊 Grafiksel Sağlık Analizi', 'en': '📊 Graphical Health Analysis'},
    'chart_water_title': {'tr': 'Su Tüketimi', 'en': 'Water Consumption'},
    'chart_target': {'tr': 'Hedef', 'en': 'Target'},
    'chart_sleep_title': {'tr': 'Uyku Düzeni', 'en': 'Sleep Pattern'},
    'chart_7_days': {'tr': '7 Gün', 'en': '7 Days'},
    'chart_1_month': {'tr': '1 Ay', 'en': '1 Month'},
    'chart_3_months': {'tr': '3 Ay', 'en': '3 Months'},
    'chart_average': {'tr': 'Ortalama', 'en': 'Average'},
    'chart_hours_per_day': {'tr': 'saat/gün', 'en': 'hours/day'},
    'chart_liters_per_day': {'tr': 'L/gün', 'en': 'L/day'},
    'prof_age_suffix': {'tr': 'yaş', 'en': 'years old'},
    'dash_charts_sub': {'tr': 'Son 3 aya kadar su ve uyku verilerini görüntüle', 'en': 'View water & sleep data up to 3 months'},
    'dash_no_sleep_logs': {'tr': 'Henüz uyku kaydı yok', 'en': 'No sleep records yet'},
    'chart_water_unit': {'tr': 'L', 'en': 'L'},
    'chart_sleep_unit': {'tr': 'sa', 'en': 'h'},
    'act_low': {'tr': 'Düşük', 'en': 'Low'},
    'act_balanced': {'tr': 'Dengeli', 'en': 'Balanced'},
    'act_active': {'tr': 'Aktif', 'en': 'Active'},
    'act_athletic': {'tr': 'Yoğun', 'en': 'Athletic'},
    
    // Weekdays
    'day_mon': {'tr': 'Pzt', 'en': 'Mon'},
    'day_tue': {'tr': 'Sal', 'en': 'Tue'},
    'day_wed': {'tr': 'Çar', 'en': 'Wed'},
    'day_thu': {'tr': 'Per', 'en': 'Thu'},
    'day_fri': {'tr': 'Cum', 'en': 'Fri'},
    'day_sat': {'tr': 'Cmt', 'en': 'Sat'},
    'day_sun': {'tr': 'Paz', 'en': 'Sun'},

    // AI Coach
    'ai_coach_chats': {'tr': 'Sohbetler', 'en': 'Chats'},
    'ai_coach_saved_chat': {'tr': 'Kayıtlı sohbet', 'en': 'Saved chat'},
    'ai_coach_save_chat': {'tr': 'Sohbeti Kaydet', 'en': 'Save Chat'},
    'ai_coach_clear': {'tr': 'Temizle', 'en': 'Clear'},
    'ai_coach_quick1': {'tr': 'Bugünkü sağlık özetim', 'en': 'My health summary today'},
    'ai_coach_quick2': {'tr': 'Su tüketimim nasıl?', 'en': 'How is my water intake?'},
    'ai_coach_quick3': {'tr': 'Kilo kontrolü tavsiyesi', 'en': 'Weight control advice'},
    'ai_coach_hint': {'tr': 'Bugünkü durumumu yorumla...', 'en': 'Interpret my status today...'},
    'ai_coach_send': {'tr': 'Gönder', 'en': 'Send'},
    'ai_coach_save_chat_title': {'tr': 'Sohbeti Kaydet', 'en': 'Save Chat'},
    'ai_coach_chat_title_hint': {'tr': 'Sohbet başlığı', 'en': 'Chat title'},
    'ai_coach_api_key_required': {'tr': 'DeepSeek API Anahtarı Gerekli', 'en': 'DeepSeek API Key Required'},
    'ai_coach_api_key_desc': {'tr': 'AI ile konuşmak için API anahtarı gerekli.', 'en': 'API key is required to chat with AI.'},
    'ai_coach_new_chat': {'tr': 'Yeni Sohbet', 'en': 'New Chat'},
    'ai_coach_no_chats': {'tr': 'Henüz kayıtlı sohbet yok.\nBir sohbeti kaydet butonu ile kaydedebilirsin.', 'en': 'No saved chats yet.\nYou can save a chat with the save button.'},
    'ai_coach_messages': {'tr': 'mesaj', 'en': 'messages'},
    'ai_coach_rename': {'tr': 'Yeniden Adlandır', 'en': 'Rename'},
    'ai_coach_new_title': {'tr': 'Yeni başlık', 'en': 'New title'},
    'ai_coach_delete_chat': {'tr': 'Sohbeti Sil', 'en': 'Delete Chat'},
    'ai_coach_delete_confirm': {'tr': 'silinecek. Emin misin?', 'en': 'will be deleted. Are you sure?'},

    // Nearby Health Facilities
    'nearby_title': {'tr': 'Yakın Sağlık Kuruluşları', 'en': 'Nearby Health Facilities'},
    'nearby_refresh': {'tr': 'Yenile', 'en': 'Refresh'},
    'nearby_search_hint': {'tr': 'Adres veya semt ara (örn: Kadıköy)', 'en': 'Search address or district (e.g. Kadikoy)'},
    'nearby_not_found': {'tr': 'bulunamadı', 'en': 'not found'},
    'nearby_load_error': {'tr': 'Sağlık kuruluşları yüklenemedi', 'en': 'Failed to load health facilities'},
    'nearby_show_map': {'tr': 'Haritada Göster', 'en': 'Show on Map'},
    'nearby_type_hospital': {'tr': 'Hastane', 'en': 'Hospital'},
    'nearby_type_pharmacy': {'tr': 'Eczane', 'en': 'Pharmacy'},
    'nearby_type_clinic': {'tr': 'Klinik', 'en': 'Clinic'},
    'nearby_type_health_center': {'tr': 'Sağlık Ocağı', 'en': 'Health Center'},
    'nearby_type_dentist': {'tr': 'Diş Hekimi', 'en': 'Dentist'},
    'nearby_type_vet': {'tr': 'Veteriner', 'en': 'Veterinary'},
    'nearby_filter_all': {'tr': 'Tümü', 'en': 'All'},
    'nearby_no_facilities': {'tr': 'Yakında sağlık kuruluşu bulunamadı', 'en': 'No health facilities found nearby'},
    'nearby_no_results': {'tr': 'Bu kategoride sonuç bulunamadı', 'en': 'No results found in this category'},

    // PDF Service
    'pdf_preparing': {'tr': 'Yapay zeka doktor özetini hazırlıyor, lütfen bekleyin...', 'en': 'AI is preparing the doctor summary, please wait...'},
    'pdf_title': {'tr': 'Doktor Raporu', 'en': 'Doctor Report'},
    'pdf_patient_info': {'tr': 'HASTA BİLGİLERİ', 'en': 'PATIENT INFORMATION'},
    'pdf_name': {'tr': 'İsim', 'en': 'Name'},
    'pdf_gender': {'tr': 'Cinsiyet', 'en': 'Gender'},
    'pdf_age': {'tr': 'Yaş', 'en': 'Age'},
    'pdf_date': {'tr': 'Tarih', 'en': 'Date'},
    'pdf_height': {'tr': 'Boy', 'en': 'Height'},
    'pdf_weight': {'tr': 'Kilo', 'en': 'Weight'},
    'pdf_blood_type': {'tr': 'Kan Grubu', 'en': 'Blood Type'},
    'pdf_health_data': {'tr': 'SAĞLIK VERİLERİ', 'en': 'HEALTH DATA'},
    'pdf_health_data_days': {'tr': '(Son @ Gün)', 'en': '(Last @ Days)'},
    'pdf_bmi': {'tr': 'VKİ', 'en': 'BMI'},
    'pdf_avg_water': {'tr': 'Ort. Su', 'en': 'Avg. Water'},
    'pdf_avg_sleep': {'tr': 'Ort. Uyku', 'en': 'Avg. Sleep'},
    'pdf_clinical_status': {'tr': 'Klinik Durum / Alerjiler:', 'en': 'Clinical Status / Allergies:'},
    'pdf_condition': {'tr': 'Durum/Tanı', 'en': 'Condition/Diagnosis'},
    'pdf_allergy': {'tr': 'Alerji', 'en': 'Allergy'},
    'pdf_ai_summary_title': {'tr': 'YAPAY ZEKA (AURA) DOKTOR ÖZETİ', 'en': 'AI (AURA) DOCTOR SUMMARY'},
    'pdf_no_critical': {'tr': 'Belirtilen kritik durum veya alerji yok.', 'en': 'No critical condition or allergy specified.'},
    'pdf_footer_warning': {'tr': 'ÖNEMLİ: Bu rapor AI tarafından üretilmiştir, tıbbi kesinlik taşımaz ve hekim değerlendirmesi yerine geçemez.', 'en': 'IMPORTANT: This report is generated by AI, has no medical certainty, and cannot replace a doctor\'s evaluation.'},
    'pdf_not_specified': {'tr': 'Belirtilmemiş', 'en': 'Not specified'},

    // Profile SOS
    'prof_sos_card': {'tr': 'Acil Durum Kartı', 'en': 'SOS Card'},
    'prof_sos_add_info': {'tr': 'Acil durum bilgisi ekle', 'en': 'Add emergency info'},
    'prof_sos_info': {'tr': 'ACİL DURUM BİLGİLERİ', 'en': 'EMERGENCY INFO'},
    'prof_gender_m': {'tr': 'Erkek', 'en': 'Male'},
    'prof_gender_f': {'tr': 'Kadın', 'en': 'Female'},
    'prof_gender_u': {'tr': 'Belirtilmedi', 'en': 'Not specified'},

    // Sleep Modal & Charts
    'sleep_date': {'tr': 'Tarih', 'en': 'Date'},
    'btn_change': {'tr': 'Değiştir', 'en': 'Change'},
    'sleep_hours_unit': {'tr': 'saat', 'en': 'hours'},
    'feeling_tired': {'tr': 'Yorgun', 'en': 'Tired'},
    'feeling_normal': {'tr': 'Normal', 'en': 'Normal'},
    'feeling_energetic': {'tr': 'Enerjik', 'en': 'Energetic'},
    'chart_sleep_feeling_energetic': {'tr': 'Enerjik', 'en': 'Energetic'},
    'chart_sleep_feeling_normal': {'tr': 'Normal', 'en': 'Normal'},
    'chart_sleep_feeling_tired': {'tr': 'Yorgun', 'en': 'Tired'},
    'prof_sos_height_weight': {'tr': 'Boy / Kilo', 'en': 'Height / Weight'},
    'prof_sos_allergies': {'tr': 'Alerjiler', 'en': 'Allergies'},
    'prof_sos_chronic': {'tr': 'Kronik Durumlar', 'en': 'Chronic Conditions'},
    'prof_sos_contact': {'tr': 'Acil Kişi', 'en': 'Emergency Contact'},
    'prof_sos_phone': {'tr': 'Acil Telefon', 'en': 'Emergency Phone'},
    'prof_sos_disclaimer': {'tr': 'Bu kart acil durumlarda sağlık personeline yardımcı olmak içindir. Bilgilerinizi Profil sayfasından güncelleyebilirsiniz.', 'en': 'This card is to assist medical personnel in emergencies. You can update your information from the Profile page.'},

    // Dashboard Water History
    'dash_water_history': {'tr': 'Bugünkü su geçmişi', 'en': 'Today\'s water history'},

    // Insights
    'insight_water_title_champ': {'tr': 'Su Şampiyonu!', 'en': 'Water Champion!'},
    'insight_water_msg_champ': {'tr': 'Günlük su hedefini fazlasıyla aştın. Harika bir hidrasyon seviyesindesin.', 'en': 'You exceeded your daily water goal by a lot. Great hydration!'},
    'insight_water_title_goal': {'tr': 'Harika Gidiyorsun!', 'en': 'Doing Great!'},
    'insight_water_msg_goal': {'tr': 'Günlük su hedefine ulaştın. Vücudun sana teşekkür ediyor. 💧', 'en': 'You reached your daily water goal. Your body thanks you. 💧'},
    'insight_water_title_half': {'tr': 'Yarıladın', 'en': 'Halfway There'},
    'insight_water_msg_half': {'tr': 'Günlük su hedefinin yarısına ulaştın. Su içmeye devam et!', 'en': 'You reached half of your daily water goal. Keep drinking!'},
    'insight_water_title_drink': {'tr': 'Su İçmeyi Unutma', 'en': 'Don\'t Forget to Drink'},
    'insight_water_msg_drink': {'tr': 'Vücudunun suya ihtiyacı var, hadi kocaman bir bardak su iç.', 'en': 'Your body needs water, let\'s drink a big glass of water.'},
    'insight_water_title_none': {'tr': 'Su İçmeye Başla', 'en': 'Start Drinking Water'},
    'insight_water_msg_none': {'tr': 'Bugün henüz hiç su içmedin. Hemen bir bardak su ile başla!', 'en': 'You haven\'t drank any water today. Start with a glass now!'},
    'insight_water_title_behind': {'tr': 'Su Molası', 'en': 'Water Break'},
    'insight_water_msg_behind': {'tr': 'Düne göre biraz geridesin, şimdi 1 bardak su içerek arayı kapatabilirsin.', 'en': 'You are a bit behind compared to yesterday, drink a glass of water now.'},
    'insight_water_title_start': {'tr': 'Güne İyi Başla', 'en': 'Start Well'},
    'insight_water_msg_start': {'tr': 'Güne enerjik başlamak için büyük bir bardak su içmelisin.', 'en': 'Drink a large glass of water to start the day energetic.'},
    
    'insight_sleep_title_perfect': {'tr': 'Mükemmel Uyku', 'en': 'Perfect Sleep'},
    'insight_sleep_msg_perfect': {'tr': 'Dün gece 8 saatten fazla uyudun. Bugün yenilenmiş hissedeceksin! ✨', 'en': 'You slept more than 8 hours last night. You will feel refreshed today! ✨'},
    'insight_sleep_title_improved': {'tr': 'Uyku Kaliten Artıyor', 'en': 'Sleep is Improving'},
    'insight_sleep_msg_improved': {'tr': 'Düne göre çok daha iyi uyudun. Bu düzeni korumaya çalış!', 'en': 'You slept much better than yesterday. Keep up this routine!'},
    'insight_sleep_title_worse': {'tr': 'Uyku Düzenin Bozuldu', 'en': 'Sleep Routine Disrupted'},
    'insight_sleep_msg_worse': {'tr': 'Düne göre çok daha az uyumuşsun. Bu gece erken yatmaya ne dersin?', 'en': 'You slept much less than yesterday. How about going to bed early tonight?'},
    'insight_sleep_title_good': {'tr': 'İyi Dinlenme', 'en': 'Good Rest'},
    'insight_sleep_msg_good': {'tr': 'Dün gece yeterli uyudun. Zihnin bugün berrak olacak! 🌙', 'en': 'You slept well last night. Your mind will be clear today! 🌙'},
    'insight_sleep_title_bad': {'tr': 'Kendine Dikkat Et', 'en': 'Take Care'},
    'insight_sleep_msg_bad': {'tr': 'Dün gece az uyumuşsun. Bugün kendine fazla yüklenmemeye çalış.', 'en': 'You slept little last night. Try not to overwork yourself today.'},
    'insight_sleep_title_none': {'tr': 'Uyku Kaydı Yok', 'en': 'No Sleep Record'},
    'insight_sleep_msg_none': {'tr': 'Dün gece nasıl uyudun? Uyku kaydını girerek takip edebilirsin.', 'en': 'How did you sleep last night? You can track it by entering a sleep record.'},
    
    'insight_mind_title_reminder': {'tr': 'Kendine Vakit Ayır', 'en': 'Take Time for Yourself'},
    'insight_mind_msg_reminder': {'tr': 'Bugün hiç duraklamadın. Sadece 1 dakikalık nefes egzersizine ne dersin? 🧘', 'en': 'You haven\'t paused at all today. How about a 1-minute breathing exercise? 🧘'},
    'insight_mind_title_done': {'tr': 'Zihin Berraklığı', 'en': 'Mental Clarity'},
    'insight_mind_msg_done': {'tr': 'Nefes egzersizi ile bugüne sakinlik kattın. Çok iyi gidiyorsun.', 'en': 'You added calmness to today with your breathing exercise. Doing well.'},
    
    'insight_med_title_done': {'tr': 'İlaçlar Tamam', 'en': 'Meds Complete'},
    'insight_med_msg_done': {'tr': 'Bugünkü planlı ilaçlarının hepsini aldın. Çok düzenlisin! 💊', 'en': 'You took all your planned medications today. Very organized! 💊'},
    'insight_med_title_missed': {'tr': 'İlaç Hatırlatması', 'en': 'Med Reminder'},
    'insight_med_msg_missed': {'tr': 'Bugün henüz almadığın ilaçların var. Saati geldiyse içmeyi unutma.', 'en': 'You have untaken medications today. Don\'t forget to take them if it\'s time.'},
    
    'insight_mood_title_great': {'tr': 'Harika Enerji', 'en': 'Great Energy'},
    'insight_mood_msg_great': {'tr': 'Bugün kendini harika hissediyorsun! Bu pozitif enerjiyi etrafına da saç.', 'en': 'You are feeling great today! Spread this positive energy around.'},
    'insight_mood_title_bad': {'tr': 'Kendine Şefkat Göster', 'en': 'Be Kind to Yourself'},
    'insight_mood_msg_bad': {'tr': 'Bugün biraz zor geçiyor gibi. Belki ılık bir duş veya sevdiğin bir müzik iyi gelebilir.', 'en': 'Today seems a bit tough. Maybe a warm shower or your favorite music would help.'},
    'insight_mood_title_none': {'tr': 'Günün Nasıl Geçiyor?', 'en': 'How is Your Day?'},
    'insight_mood_msg_none': {'tr': 'Bugün kendini nasıl hissettiğini henüz kaydetmedin.', 'en': 'You haven\'t logged how you feel today.'},

    'insight_general_title': {'tr': 'Günün Sözü', 'en': 'Quote of the Day'},
    'insight_general_msg': {'tr': 'Sağlığın en büyük zenginliğindir. Bugün kendine iyi bakmayı unutma! ✨', 'en': 'Health is your greatest wealth. Don\'t forget to take care of yourself today! ✨'},
  };

  static String get(String key, String langCode) {
    if (_translations.containsKey(key)) {
      return _translations[key]![langCode] ?? _translations[key]!['tr']!;
    }
    return key;
  }
}
