class AppStrings {
  final String code;
  const AppStrings._(this.code);

  static const AppStrings en = AppStrings._('en');
  static const AppStrings tr = AppStrings._('tr');
  static const AppStrings da = AppStrings._('da');
  static const AppStrings de = AppStrings._('de');
  static const AppStrings ar = AppStrings._('ar');

  static AppStrings get(String code) {
    switch (code) {
      case 'tr':
        return tr;
      case 'da':
        return da;
      case 'de':
        return de;
      case 'ar':
        return ar;
      case 'en':
      default:
        return en;
    }
  }

  // Header & General
  String get settings => switch (code) {
        'tr' => 'Ayarlar',
        'da' => 'Indstillinger',
        'de' => 'Einstellungen',
        'ar' => 'الإعدادات',
        _ => 'Settings',
      };

  String get location => switch (code) {
        'tr' => 'KONUM',
        'da' => 'LOKATION',
        'de' => 'STANDORT',
        'ar' => 'الموقع',
        _ => 'LOCATION',
      };

  String get device => switch (code) {
        'tr' => 'Cihaz',
        'da' => 'Enhed',
        'de' => 'Gerät',
        'ar' => 'الجهاز',
        _ => 'Device',
      };

  String get deviceCaption => switch (code) {
        'tr' => 'Pil dostu • GPS yok',
        'da' => 'Batterisparende • Ingen GPS',
        'de' => 'Akkusparend • Kein GPS',
        'ar' => 'توفير البطارية • بدون GPS',
        _ => 'Battery-saver • No GPS',
      };

  String get networkIp => switch (code) {
        'tr' => 'Ağ IP',
        'da' => 'Netværks-IP',
        'de' => 'Netzwerk-IP',
        'ar' => 'عنوان IP',
        _ => 'Network IP',
      };

  String get zeroPermissions => switch (code) {
        'tr' => 'Sıfır izin',
        'da' => 'Nul tilladelser',
        'de' => 'Keine Berechtigungen',
        'ar' => 'بدون أذونات',
        _ => 'Zero permissions',
      };

  String get manualCity => switch (code) {
        'tr' => 'Manuel Şehir',
        'da' => 'Manuel by',
        'de' => 'Stadt manuell',
        'ar' => 'مدينة يدوية',
        _ => 'Manual City',
      };

  String get pickFromList => switch (code) {
        'tr' => 'Listeden seç',
        'da' => 'Vælg fra liste',
        'de' => 'Aus Liste wählen',
        'ar' => 'اختر من القائمة',
        _ => 'Pick from list',
      };

  String get selectCountry => switch (code) {
        'tr' => 'Ülke Seçin',
        'da' => 'Vælg land',
        'de' => 'Land wählen',
        'ar' => 'اختر الدولة',
        _ => 'Select Country',
      };

  String get selectCity => switch (code) {
        'tr' => 'Şehir Seçin',
        'da' => 'Vælg by',
        'de' => 'Stadt wählen',
        'ar' => 'اختر المدينة',
        _ => 'Select City',
      };

  String get customCityName => switch (code) {
        'tr' => 'Özel Şehir Adı',
        'da' => 'Brugerdefineret bynavn',
        'de' => 'Eigener Stadtname',
        'ar' => 'اسم المدينة',
        _ => 'Custom City Name',
      };

  String get customCountryName => switch (code) {
        'tr' => 'Özel Ülke Adı',
        'da' => 'Brugerdefineret landenavn',
        'de' => 'Eigener Ländername',
        'ar' => 'اسم الدولة',
        _ => 'Custom Country Name',
      };

  String get applyLocation => switch (code) {
        'tr' => 'Konumu Uygula',
        'da' => 'Anvend lokation',
        'de' => 'Standort anwenden',
        'ar' => 'تطبيق الموقع',
        _ => 'Apply Location',
      };

  String get calculationMethod => switch (code) {
        'tr' => 'HESAPLAMA YÖNTEMİ',
        'da' => 'BEREGNINGSMETODE',
        'de' => 'BERECHNUNGSMETHODE',
        'ar' => 'طريقة الحساب',
        _ => 'CALCULATION METHOD',
      };

  String get preferences => switch (code) {
        'tr' => 'TERCİHLER',
        'da' => 'PRÆFERENCER',
        'de' => 'EINSTELLUNGEN',
        'ar' => 'التفضيلات',
        _ => 'PREFERENCES',
      };

  String get language => switch (code) {
        'tr' => 'Uygulama Dili',
        'da' => 'App-sprog',
        'de' => 'App-Sprache',
        'ar' => 'لغة التطبيق',
        _ => 'App Language',
      };

  String get turkishPrayerNames => switch (code) {
        'tr' => 'Türkçe Vakit İsimleri',
        'da' => 'Tyrkiske bønnenavne',
        'de' => 'Türkische Gebetsnamen',
        'ar' => 'أسماء الصلوات التركية',
        _ => 'Turkish Prayer Names',
      };

  String get zoomEnhancedMode => switch (code) {
        'tr' => 'Gelişmiş Yakınlaştırma Modu',
        'da' => 'Forstørret tilstand',
        'de' => 'Erweiterter Zoom-Modus',
        'ar' => 'وضع التكبير المحسّن',
        _ => 'Zoom Enhanced Mode',
      };

  String get zoomEnhancedCaption => switch (code) {
        'tr' => 'Daha iyi okunabilirlik için büyük yazı ve sayılar',
        'da' => 'Stor tekst og tal for forbedret synlighed',
        'de' => 'Großer Text und Zahlen für bessere Lesbarkeit',
        'ar' => 'نصوص وأرقام كبيرة لرؤية أوضح',
        _ => 'Large text & numbers for enhanced visibility',
      };

  String get prayerNotifications => switch (code) {
        'tr' => 'Vakit Bildirimleri',
        'da' => 'Bønnenotifikationer',
        'de' => 'Gebetsbenachrichtigungen',
        'ar' => 'إشعارات الصلاة',
        _ => 'Prayer Notifications',
      };

  String get prayerNotificationsCaption => switch (code) {
        'tr' => 'Vakit girdiğinde sessiz hatırlatıcı banner',
        'da' => 'Diskret påmindelsesbanner ved bønnetider',
        'de' => 'Dezenter Hinweis zu Gebetszeiten',
        'ar' => 'شريط تذكير لطيف عند أوقات الصلاة',
        _ => 'Subtle reminder banner at prayer times',
      };

  String get pinnedShadeNotification => switch (code) {
        'tr' => 'Sabit Bildirim Paneli',
        'da' => 'Fastgjort notifikationspanel',
        'de' => 'Fixierte Benachrichtigung',
        'ar' => 'إشعار ثابت في شريط الإشعارات',
        _ => 'Pinned Shade Notification',
      };

  String get pinnedShadeCaption => switch (code) {
        'tr' => 'Bildirim panelinde sürekli vakitler • %0 arka plan pili',
        'da' => 'Faste bønnetider i notifikationer • 0% baggrundsbatteri',
        'de' => 'Dauerhafte Gebetszeiten in der Leiste • 0% Hintergrundakku',
        'ar' => 'أوقات الصلاة الدائمة في الإشعارات • 0% استهلاك بطارية',
        _ => 'Persistent prayer times in shade • 0% background battery',
      };

  String get appearanceTheme => switch (code) {
        'tr' => 'GÖRÜNÜM VE TEMA',
        'da' => 'UDSEENDE & TEMA',
        'de' => 'ERSCHEINUNGSBILD & THEMA',
        'ar' => 'المظهر والسمة',
        _ => 'APPEARANCE & THEME',
      };

  String get appThemePalette => switch (code) {
        'tr' => 'Uygulama Teması',
        'da' => 'App-temapalet',
        'de' => 'App-Farbpalette',
        'ar' => 'لوحة ألوان التطبيق',
        _ => 'App Theme Palette',
      };

  String get appAccentColor => switch (code) {
        'tr' => 'Uygulama Vurgu Rengi',
        'da' => 'App-accentfarve',
        'de' => 'App-Akzentfarbe',
        'ar' => 'لون تمييز التطبيق',
        _ => 'App Accent Color',
      };

  String get homeScreenWidgets => switch (code) {
        'tr' => 'ANA EKRAN BİLEŞENLERİ',
        'da' => 'HJEMMESKÆRMSWIDGETS',
        'de' => 'STARTBILDSCHIRM-WIDGETS',
        'ar' => 'عناصر الشاشة الرئيسية',
        _ => 'HOME SCREEN WIDGETS',
      };

  String get backgroundStyle => switch (code) {
        'tr' => 'Arka Plan Stili',
        'da' => 'Baggrundsstil',
        'de' => 'Hintergrundstil',
        'ar' => 'نمط الخلفية',
        _ => 'Background Style',
      };

  String get accentColor => switch (code) {
        'tr' => 'Vurgu Rengi',
        'da' => 'Accentfarve',
        'de' => 'Akzentfarbe',
        'ar' => 'لون التمييز',
        _ => 'Accent Color',
      };

  String get showHeaderInWidgets => switch (code) {
        'tr' => 'Bileşenlerde Başlığı Göster',
        'da' => 'Vis overskrift i widgets',
        'de' => 'Kopfzeile in Widgets anzeigen',
        'ar' => 'إظهار الشريط في الأدوات',
        _ => 'Show Header in Widgets',
      };

  String get showHeaderCaption => switch (code) {
        'tr' => 'Konum ve Hicri tarih başlık çubuğunu göster',
        'da' => 'Vis placering og Hijri-datobjælke',
        'de' => 'Standort und Hidschri-Datum anzeigen',
        'ar' => 'عرض شريط الموقع والتاريخ الهجري',
        _ => 'Display location and Hijri date header bar',
      };

  String get widgetFontSize => switch (code) {
        'tr' => 'Bileşen Yazı Boyutu',
        'da' => 'Widget skriftstørrelse',
        'de' => 'Widget-Schriftgröße',
        'ar' => 'حجم خط الأدوات',
        _ => 'Widget Font Size',
      };

  String get standard => switch (code) {
        'tr' => 'Standart',
        'da' => 'Standard',
        'de' => 'Standard',
        'ar' => 'قياسي',
        _ => 'Standard',
      };

  String get large => switch (code) {
        'tr' => 'Büyük (+%15)',
        'da' => 'Stor (+15%)',
        'de' => 'Groß (+15%)',
        'ar' => 'كبير (+15%)',
        _ => 'Large (+15%)',
      };

  String get xlarge => switch (code) {
        'tr' => 'Çok Büyük (+%30)',
        'da' => 'Ekstra stor (+30%)',
        'de' => 'Sehr groß (+30%)',
        'ar' => 'كبير جداً (+30%)',
        _ => 'X-Large (+30%)',
      };

  String get typography => switch (code) {
        'tr' => 'TİPOGRAFİ',
        'da' => 'TYPOGRAFI',
        'de' => 'TYPOGRAFIE',
        'ar' => 'الخطوط',
        _ => 'TYPOGRAPHY',
      };

  String get cacheAndStorage => switch (code) {
        'tr' => 'ÖNBELLEK VE DEPOLAMA',
        'da' => 'CACHE & LAGER',
        'de' => 'CACHE & SPEICHER',
        'ar' => 'التخزين المؤقت',
        _ => 'CACHE & STORAGE',
      };

  String get offlineSchedule => switch (code) {
        'tr' => 'Çevrimdışı Vakitler',
        'da' => 'Offline tidsplan',
        'de' => 'Offline-Zeitplan',
        'ar' => 'الجدول بدون إنترنت',
        _ => 'Offline Schedule',
      };

  String get offlineScheduleCaption => switch (code) {
        'tr' => 'İnternetsiz kullanım için yerel olarak saklanır',
        'da' => 'Gemt lokalt til brug uden netværk',
        'de' => 'Lokal gespeichert für Offline-Nutzung',
        'ar' => 'محفوظ محلياً للعمل بدون إنترنت',
        _ => 'Saved locally for zero-network use',
      };

  String get resync => switch (code) {
        'tr' => 'Yenile',
        'da' => 'Genindlæs',
        'de' => 'Neu laden',
        'ar' => 'إعادة مزامنة',
        _ => 'Re-sync',
      };

  String get aboutAndUpdates => switch (code) {
        'tr' => 'HAKKINDA VE GÜNCELLEMELER',
        'da' => 'OM & OPDATERINGER',
        'de' => 'ÜBER & UPDATES',
        'ar' => 'حول والتحديثات',
        _ => 'ABOUT & UPDATES',
      };

  String get minarPrayerTimes => switch (code) {
        'tr' => 'Minar Vakitler',
        'da' => 'Minar Bønnetider',
        'de' => 'Minar Gebetszeiten',
        'ar' => 'مواقيت الصلاة منار',
        _ => 'Minar Prayer Times',
      };

  String get checkForUpdates => switch (code) {
        'tr' => 'Güncellemeleri denetle',
        'da' => 'Søg efter opdateringer',
        'de' => 'Nach Updates suchen',
        'ar' => 'التحقق من التحديثات',
        _ => 'Check for updates',
      };

  String get checkingGithub => switch (code) {
        'tr' => 'GitHub denetleniyor...',
        'da' => 'Tjekker GitHub...',
        'de' => 'Prüfe GitHub...',
        'ar' => 'جاري فحص GitHub...',
        _ => 'Checking GitHub...',
      };

  String get upToDate => switch (code) {
        'tr' => 'Uygulama Güncel',
        'da' => 'Opdateret',
        'de' => 'Aktuell',
        'ar' => 'محدث',
        _ => 'Up to Date',
      };

  String get updateAvailable => switch (code) {
        'tr' => 'Güncelleme Mevcut',
        'da' => 'Opdatering tilgængelig',
        'de' => 'Update verfügbar',
        'ar' => 'تحديث متاح',
        _ => 'Update Available',
      };

  String get downloadApk => switch (code) {
        'tr' => 'Güncellemeyi İndir',
        'da' => 'Hent opdatering',
        'de' => 'Update herunterladen',
        'ar' => 'تحميل التحديث',
        _ => 'Download Update',
      };

  String get downloadingUpdate => switch (code) {
        'tr' => 'İndiriliyor...',
        'da' => 'Henter opdatering...',
        'de' => 'Update wird heruntergeladen...',
        'ar' => 'جاري تحميل التحديث...',
        _ => 'Downloading...',
      };

  String get installUpdate => switch (code) {
        'tr' => 'Şimdi Güncelle',
        'da' => 'Opdater nu',
        'de' => 'Jetzt aktualisieren',
        'ar' => 'تثبيت التحديث',
        _ => 'Update Now',
      };

  String get later => switch (code) {
        'tr' => 'Daha sonra',
        'da' => 'Senere',
        'de' => 'Später',
        'ar' => 'لاحقاً',
        _ => 'Later',
      };

  String get ok => switch (code) {
        'tr' => 'Tamam',
        'da' => 'OK',
        'de' => 'OK',
        'ar' => 'موافق',
        _ => 'OK',
      };

  // Home Screen
  String get nextPrayer => switch (code) {
        'tr' => 'SONRAKİ VAKİT',
        'da' => 'NÆSTE BØN',
        'de' => 'NÄCHSTES GEBET',
        'ar' => 'الصلاة القادمة',
        _ => 'NEXT PRAYER',
      };

  String get tomorrowFajr => switch (code) {
        'tr' => 'YARINKİ İMSAK',
        'da' => 'I MORGEN FAJR',
        'de' => 'MORGEN FAJR',
        'ar' => 'فجر الغد',
        _ => 'TOMORROW FAJR',
      };

  String get remaining => switch (code) {
        'tr' => 'kaldı',
        'da' => 'tilbage',
        'de' => 'verbleibend',
        'ar' => 'متبقي',
        _ => 'remaining',
      };

  String get todaySchedule => switch (code) {
        'tr' => 'BUGÜNKÜ VAKİTLER',
        'da' => 'DAGENS TIDER',
        'de' => 'HEUTIGER PLAN',
        'ar' => 'جدول اليوم',
        _ => "TODAY'S SCHEDULE",
      };

  String get tomorrowSchedule => switch (code) {
        'tr' => 'YARINKİ VAKİTLER',
        'da' => 'I MORGENS TIDER',
        'de' => 'MORGIGER PLAN',
        'ar' => 'جدول الغد',
        _ => "TOMORROW'S SCHEDULE",
      };

  String get swipeDays => switch (code) {
        'tr' => 'Günleri kaydır',
        'da' => 'Stryg dage',
        'de' => 'Tage wischen',
        'ar' => 'اسحب الأيام',
        _ => 'Swipe days',
      };

  String get today => switch (code) {
        'tr' => 'Bugün',
        'da' => 'I dag',
        'de' => 'Heute',
        'ar' => 'اليوم',
        _ => 'Today',
      };

  String get tomorrow => switch (code) {
        'tr' => 'Yarın',
        'da' => 'I morgen',
        'de' => 'Morgen',
        'ar' => 'غداً',
        _ => 'Tomorrow',
      };

  String get updatingPrayerTimes => switch (code) {
        'tr' => 'Vakitler güncelleniyor...',
        'da' => 'Opdaterer bønnetider...',
        'de' => 'Gebetszeiten werden aktualisiert...',
        'ar' => 'جاري تحديث مواقيت الصلاة...',
        _ => 'Updating prayer times...',
      };

  String get sendTestNotification => switch (code) {
        'tr' => 'Test Bildirimi Gönder',
        'da' => 'Send testnotifikation',
        'de' => 'Testbenachrichtigung senden',
        'ar' => 'إرسال إشعار تجريبي',
        _ => 'Send Test Notification',
      };

  String get testNotificationSent => switch (code) {
        'tr' => 'Test bildirimi gönderildi',
        'da' => 'Testnotifikation sendt',
        'de' => 'Testbenachrichtigung gesendet',
        'ar' => 'تم إرسال إشعار الاختبار',
        _ => 'Test notification sent',
      };
}
