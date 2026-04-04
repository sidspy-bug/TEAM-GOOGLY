import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Centralized app localizations.
/// Supports: English (en), Hindi (hi), Tamil (ta), Marathi (mr).
///
/// Usage:
///   final l = AppLocalizations.of(context);
///   Text(l.dashboard)
class AppLocalizations {
  AppLocalizations(this.locale) {
    switch (locale.languageCode) {
      case 'hi':
        _t = const _Hi();
        break;
      case 'ta':
        _t = const _Ta();
        break;
      case 'mr':
        _t = const _Mr();
        break;
      default:
        _t = const _En();
    }
  }

  final Locale locale;
  late final _Strings _t;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _Delegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('mr'),
  ];

  // ── App ─────────────────────────────────────────────────────────────
  String get appName => _t.appName;

  // ── Common ───────────────────────────────────────────────────────────
  String get save => _t.save;
  String get cancel => _t.cancel;
  String get close => _t.close;
  String get ok => _t.ok;
  String get retry => _t.retry;
  String get back => _t.back;
  String get next => _t.next;
  String get delete => _t.delete;
  String get edit => _t.edit;
  String get loading => _t.loading;
  String get error => _t.error;
  String get success => _t.success;
  String get noData => _t.noData;
  String get notSet => _t.notSet;
  String get unknown => _t.unknown;

  // ── Navigation ───────────────────────────────────────────────────────
  String get navDashboard => _t.navDashboard;
  String get navInventory => _t.navInventory;
  String get navSalesHistory => _t.navSalesHistory;
  String get navSettings => _t.navSettings;

  // ── Login ────────────────────────────────────────────────────────────
  String get loginTitle => _t.loginTitle;
  String get email => _t.email;
  String get password => _t.password;
  String get signIn => _t.signIn;
  String get forgotPassword => _t.forgotPassword;
  String get orContinueWith => _t.orContinueWith;
  String get continueWithGoogle => _t.continueWithGoogle;
  String get continueWithFacebook => _t.continueWithFacebook;
  String get dontHaveAccount => _t.dontHaveAccount;
  String get phoneLabel => _t.phoneLabel;
  String get phoneNumber => _t.phoneNumber;
  String get sendOtp => _t.sendOtp;
  String get enterOtp => _t.enterOtp;
  String get verifyOtp => _t.verifyOtp;
  String get emailRequired => _t.emailRequired;
  String get enterValidEmail => _t.enterValidEmail;
  String get passwordRequired => _t.passwordRequired;
  String get minSixChars => _t.minSixChars;
  String get otpSent => _t.otpSent;
  String get invalidOtp => _t.invalidOtp;
  String get signedInWithGoogle => _t.signedInWithGoogle;
  String get signedInWithFacebook => _t.signedInWithFacebook;
  String get requiresRecentLogin => _t.requiresRecentLogin;

  // ── Signup ───────────────────────────────────────────────────────────
  String get createAccount => _t.createAccount;
  String get fullName => _t.fullName;
  String get confirmPassword => _t.confirmPassword;
  String get signUp => _t.signUp;
  String get alreadyHaveAccount => _t.alreadyHaveAccount;
  String get joinGrowthOS => _t.joinGrowthOS;
  String get nameRequired => _t.nameRequired;
  String get confirmPasswordRequired => _t.confirmPasswordRequired;
  String get passwordsDoNotMatch => _t.passwordsDoNotMatch;
  String get orSignUpWith => _t.orSignUpWith;

  // ── Forgot Password ──────────────────────────────────────────────────
  String get resetPassword => _t.resetPassword;
  String get resetPasswordDesc => _t.resetPasswordDesc;
  String get sendResetLink => _t.sendResetLink;
  String get backToLogin => _t.backToLogin;
  String get checkYourEmail => _t.checkYourEmail;
  String get emailSentDesc => _t.emailSentDesc;
  String get backToSignIn => _t.backToSignIn;
  String get didntReceiveEmail => _t.didntReceiveEmail;
  String get resend => _t.resend;
  String get checkSpamTip => _t.checkSpamTip;
  String get stepEmailSent => _t.stepEmailSent;
  String get stepClickLink => _t.stepClickLink;
  String get stepNewPassword => _t.stepNewPassword;
  String resendInSeconds(int s) => _t.resendInSeconds(s);

  // ── Onboarding ───────────────────────────────────────────────────────
  String get letsSetupStore => _t.letsSetupStore;
  String get whatsYourName => _t.whatsYourName;
  String get nameDisplayedProfile => _t.nameDisplayedProfile;
  String get nameYourShop => _t.nameYourShop;
  String get shopNameDisplayed => _t.shopNameDisplayed;
  String get chooseProfileIcon => _t.chooseProfileIcon;
  String get getStarted => _t.getStarted;
  String get skipForNow => _t.skipForNow;
  String get yourName => _t.yourName;
  String get shopNameLabel => _t.shopNameLabel;
  String get profileLabel => _t.profileLabel;
  String get pleaseEnterName => _t.pleaseEnterName;
  String get pleaseEnterShopName => _t.pleaseEnterShopName;
  String get pickIconHint => _t.pickIconHint;
  String get pickIconHintWithPhoto => _t.pickIconHintWithPhoto;

  // ── Dashboard ────────────────────────────────────────────────────────
  String get totalSales => _t.totalSales;
  String get totalProfit => _t.totalProfit;
  String get unitsSold => _t.unitsSold;
  String get lowStockCount => _t.lowStockCount;
  String get topProducts => _t.topProducts;
  String get salesTrend => _t.salesTrend;
  String get aiInsights => _t.aiInsights;
  String get errorLoadingDashboard => _t.errorLoadingDashboard;
  String get lowStockProducts => _t.lowStockProducts;
  String get stockLabel => _t.stockLabel;

  // ── Inventory ────────────────────────────────────────────────────────
  String get inventory => _t.inventory;
  String get productsLabel => _t.productsLabel;
  String get product => _t.product;
  String get category => _t.category;
  String get currentStock => _t.currentStock;
  String get sellPrice => _t.sellPrice;
  String get costPrice => _t.costPrice;
  String get revenueLabel => _t.revenueLabel;
  String get estimatedProfit => _t.estimatedProfit;
  String get lastTxnDate => _t.lastTxnDate;
  String get idLabel => _t.idLabel;

  // ── Sales History ────────────────────────────────────────────────────
  String get salesHistory => _t.salesHistory;
  String get dateLabel => _t.dateLabel;
  String get noSalesFound => _t.noSalesFound;
  String get filterByDate => _t.filterByDate;
  String get clearFilter => _t.clearFilter;
  String get modeLabel => _t.modeLabel;
  String get quantityLabel => _t.quantityLabel;
  String get totalLabel => _t.totalLabel;
  String get profitLabel => _t.profitLabel;
  String get transactionsLabel => _t.transactionsLabel;
  String get settings => _t.settings;
  String get account => _t.account;
  String get shopName => _t.shopName;
  String get currency => _t.currency;
  String get notifications => _t.notifications;
  String get theme => _t.theme;
  String get language => _t.language;
  String get about => _t.about;
  String get logout => _t.logout;
  String get selectLanguage => _t.selectLanguage;
  String get selectCurrency => _t.selectCurrency;
  String get editShopName => _t.editShopName;
  String get lowStockAlertsEnabled => _t.lowStockAlertsEnabled;
  String get alertsDisabled => _t.alertsDisabled;
  String get darkTheme => _t.darkTheme;
  String get lightTheme => _t.lightTheme;
  String get notificationsEnabledMsg => _t.notificationsEnabledMsg;
  String get notificationsDisabledMsg => _t.notificationsDisabledMsg;
  String get darkThemeMsg => _t.darkThemeMsg;
  String get lightThemeMsg => _t.lightThemeMsg;
  String get shopNameUpdated => _t.shopNameUpdated;
  String get accountDetails => _t.accountDetails;
  String get nameLabel => _t.nameLabel;
  String get providerLabel => _t.providerLabel;
  String get createdLabel => _t.createdLabel;
  String get deleteAccount => _t.deleteAccount;
  String get thisWillDelete => _t.thisWillDelete;
  String get deleteItemCredentials => _t.deleteItemCredentials;
  String get deleteItemShopSettings => _t.deleteItemShopSettings;
  String get deleteItemLocalData => _t.deleteItemLocalData;
  String get cannotBeUndone => _t.cannotBeUndone;
  String get typeDeleteToConfirm => _t.typeDeleteToConfirm;
  String get deletePermanently => _t.deletePermanently;
  String get notSignedIn => _t.notSignedIn;
  String get aboutVersion => _t.aboutVersion;
  String get aboutDescription => _t.aboutDescription;

  // ── Manual Entry ─────────────────────────────────────────────────────
  String get addProduct => _t.addProduct;
  String get recordSale => _t.recordSale;
  String get productNameLabel => _t.productNameLabel;
  String get sellingPriceLabel => _t.sellingPriceLabel;
  String get initialStock => _t.initialStock;
  String get selectProduct => _t.selectProduct;
  String get transactionMode => _t.transactionMode;
  String get productAddedSuccess => _t.productAddedSuccess;
  String get saleRecordedSuccess => _t.saleRecordedSuccess;
  String get fieldRequired => _t.fieldRequired;
  String get enterValidNumber => _t.enterValidNumber;
  String get noProductsAvailable => _t.noProductsAvailable;
  String get addProductDesc => _t.addProductDesc;
  String get recordSaleDesc => _t.recordSaleDesc;

  // ── Language names (shown in picker) ─────────────────────────────────
  String languageName(String code) {
    switch (code) {
      case 'hi': return 'हिन्दी';
      case 'ta': return 'தமிழ்';
      case 'mr': return 'मराठी';
      default:   return 'English';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delegate
// ─────────────────────────────────────────────────────────────────────────────

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'ta', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_Delegate old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract base for all translations
// ─────────────────────────────────────────────────────────────────────────────

abstract class _Strings {
  const _Strings();

  // App
  String get appName;

  // Common
  String get save;
  String get cancel;
  String get close;
  String get ok;
  String get retry;
  String get back;
  String get next;
  String get delete;
  String get edit;
  String get loading;
  String get error;
  String get success;
  String get noData;
  String get notSet;
  String get unknown;

  // Navigation
  String get navDashboard;
  String get navInventory;
  String get navSalesHistory;
  String get navSettings;

  // Login
  String get loginTitle;
  String get email;
  String get password;
  String get signIn;
  String get forgotPassword;
  String get orContinueWith;
  String get continueWithGoogle;
  String get continueWithFacebook;
  String get dontHaveAccount;
  String get phoneLabel;
  String get phoneNumber;
  String get sendOtp;
  String get enterOtp;
  String get verifyOtp;
  String get emailRequired;
  String get enterValidEmail;
  String get passwordRequired;
  String get minSixChars;
  String get otpSent;
  String get invalidOtp;
  String get signedInWithGoogle;
  String get signedInWithFacebook;
  String get requiresRecentLogin;

  // Signup
  String get createAccount;
  String get fullName;
  String get confirmPassword;
  String get signUp;
  String get alreadyHaveAccount;
  String get joinGrowthOS;
  String get nameRequired;
  String get confirmPasswordRequired;
  String get passwordsDoNotMatch;
  String get orSignUpWith;

  // Forgot Password
  String get resetPassword;
  String get resetPasswordDesc;
  String get sendResetLink;
  String get backToLogin;
  String get checkYourEmail;
  String get emailSentDesc;
  String get backToSignIn;
  String get didntReceiveEmail;
  String get resend;
  String get checkSpamTip;
  String get stepEmailSent;
  String get stepClickLink;
  String get stepNewPassword;
  String resendInSeconds(int s);

  // Onboarding
  String get letsSetupStore;
  String get whatsYourName;
  String get nameDisplayedProfile;
  String get nameYourShop;
  String get shopNameDisplayed;
  String get chooseProfileIcon;
  String get getStarted;
  String get skipForNow;
  String get yourName;
  String get shopNameLabel;
  String get profileLabel;
  String get pleaseEnterName;
  String get pleaseEnterShopName;
  String get pickIconHint;
  String get pickIconHintWithPhoto;

  // Dashboard
  String get totalSales;
  String get totalProfit;
  String get unitsSold;
  String get lowStockCount;
  String get topProducts;
  String get salesTrend;
  String get aiInsights;
  String get errorLoadingDashboard;
  String get lowStockProducts;
  String get stockLabel;

  // Inventory
  String get inventory;
  String get productsLabel;
  String get product;
  String get category;
  String get currentStock;
  String get sellPrice;
  String get costPrice;
  String get revenueLabel;
  String get estimatedProfit;
  String get lastTxnDate;
  String get idLabel;

  // Sales History
  String get salesHistory;
  String get dateLabel;
  String get noSalesFound;
  String get filterByDate;
  String get clearFilter;
  String get modeLabel;
  String get quantityLabel;
  String get totalLabel;
  String get profitLabel;
  String get transactionsLabel;

  // Settings
  String get settings;
  String get account;
  String get shopName;
  String get currency;
  String get notifications;
  String get theme;
  String get language;
  String get about;
  String get logout;
  String get selectLanguage;
  String get selectCurrency;
  String get editShopName;
  String get lowStockAlertsEnabled;
  String get alertsDisabled;
  String get darkTheme;
  String get lightTheme;
  String get notificationsEnabledMsg;
  String get notificationsDisabledMsg;
  String get darkThemeMsg;
  String get lightThemeMsg;
  String get shopNameUpdated;
  String get accountDetails;
  String get nameLabel;
  String get providerLabel;
  String get createdLabel;
  String get deleteAccount;
  String get thisWillDelete;
  String get deleteItemCredentials;
  String get deleteItemShopSettings;
  String get deleteItemLocalData;
  String get cannotBeUndone;
  String get typeDeleteToConfirm;
  String get deletePermanently;
  String get notSignedIn;
  String get aboutVersion;
  String get aboutDescription;

  // Manual Entry
  String get addProduct;
  String get recordSale;
  String get productNameLabel;
  String get sellingPriceLabel;
  String get initialStock;
  String get selectProduct;
  String get transactionMode;
  String get productAddedSuccess;
  String get saleRecordedSuccess;
  String get fieldRequired;
  String get enterValidNumber;
  String get noProductsAvailable;
  String get addProductDesc;
  String get recordSaleDesc;
}

// ─────────────────────────────────────────────────────────────────────────────
// English
// ─────────────────────────────────────────────────────────────────────────────

class _En extends _Strings {
  const _En();

  @override String get appName => 'GrowthOS';

  @override String get save => 'Save';
  @override String get cancel => 'Cancel';
  @override String get close => 'Close';
  @override String get ok => 'OK';
  @override String get retry => 'Retry';
  @override String get back => 'Back';
  @override String get next => 'Next';
  @override String get delete => 'Delete';
  @override String get edit => 'Edit';
  @override String get loading => 'Loading...';
  @override String get error => 'Error';
  @override String get success => 'Success';
  @override String get noData => 'No data';
  @override String get notSet => 'Not set';
  @override String get unknown => 'Unknown';

  @override String get navDashboard => 'Dashboard';
  @override String get navInventory => 'Inventory';
  @override String get navSalesHistory => 'History';
  @override String get navSettings => 'Settings';

  @override String get loginTitle => 'Sign in to your account';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get signIn => 'Sign In';
  @override String get forgotPassword => 'Forgot Password?';
  @override String get orContinueWith => 'or continue with';
  @override String get continueWithGoogle => 'Continue with Google';
  @override String get continueWithFacebook => 'Continue with Facebook';
  @override String get dontHaveAccount => "Don't have an account? Sign up";
  @override String get phoneLabel => 'Phone';
  @override String get phoneNumber => 'Phone Number';
  @override String get sendOtp => 'Send OTP';
  @override String get enterOtp => 'Enter 6-digit OTP';
  @override String get verifyOtp => 'Verify OTP';
  @override String get emailRequired => 'Email is required';
  @override String get enterValidEmail => 'Enter a valid email';
  @override String get passwordRequired => 'Password is required';
  @override String get minSixChars => 'Minimum 6 characters';
  @override String get otpSent => 'OTP sent to your phone';
  @override String get invalidOtp => 'Enter a valid 6-digit OTP';
  @override String get signedInWithGoogle => 'Signed in with Google successfully!';
  @override String get signedInWithFacebook => 'Signed in with Facebook successfully!';
  @override String get requiresRecentLogin => 'For security, please sign out, sign back in, and try again.';

  @override String get createAccount => 'Create Account';
  @override String get fullName => 'Full Name';
  @override String get confirmPassword => 'Confirm Password';
  @override String get signUp => 'Sign Up';
  @override String get alreadyHaveAccount => 'Already have an account? Sign in';
  @override String get joinGrowthOS => 'Join GrowthOS';
  @override String get nameRequired => 'Name is required';
  @override String get confirmPasswordRequired => 'Confirm your password';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get orSignUpWith => 'or sign up with';
  @override String get resetPassword => 'Reset Password';
  @override String get resetPasswordDesc => "Enter your registered email and we'll send you a link to reset your password.";
  @override String get sendResetLink => 'Send Reset Link';
  @override String get backToLogin => 'Back to Login';
  @override String get checkYourEmail => 'Check Your Email';
  @override String get emailSentDesc => "We've sent a password reset link to your email. Click the link in the email to set a new password.";
  @override String get backToSignIn => 'Back to Sign In';
  @override String get didntReceiveEmail => "Didn't receive the email? ";
  @override String get resend => 'Resend';
  @override String get checkSpamTip => "Check your spam/junk folder if you don't see the email. The link expires in 1 hour.";
  @override String get stepEmailSent => 'Email sent';
  @override String get stepClickLink => 'Click link';
  @override String get stepNewPassword => 'New password';
  @override String resendInSeconds(int s) => 'Resend in ${s}s';

  @override String get letsSetupStore => "Let's set up your store";
  @override String get whatsYourName => "What's your name?";
  @override String get nameDisplayedProfile => 'This will be displayed on your profile';
  @override String get nameYourShop => 'Name your shop';
  @override String get shopNameDisplayed => 'This will appear in your sidebar and dashboard';
  @override String get chooseProfileIcon => 'Choose a profile icon';
  @override String get getStarted => 'Get Started';
  @override String get skipForNow => 'Skip for now';
  @override String get yourName => 'Your Name';
  @override String get shopNameLabel => 'Shop Name';
  @override String get profileLabel => 'Profile';
  @override String get pleaseEnterName => 'Please enter your name';
  @override String get pleaseEnterShopName => 'Please enter your shop name';
  @override String get pickIconHint => 'Pick an icon to represent your store';
  @override String get pickIconHintWithPhoto => 'Your Google/Facebook photo is already set. Pick an icon to change it.';

  @override String get totalSales => 'Total Sales';
  @override String get totalProfit => 'Total Profit';
  @override String get unitsSold => 'Units Sold';
  @override String get lowStockCount => 'Low Stock';
  @override String get topProducts => 'Top Products';
  @override String get salesTrend => 'Sales Trend';
  @override String get aiInsights => 'AI Insights';
  @override String get errorLoadingDashboard => 'Error loading dashboard';
  @override String get lowStockProducts => 'Low Stock Products';
  @override String get stockLabel => 'Stock';

  @override String get inventory => 'Inventory';
  @override String get productsLabel => 'products';
  @override String get product => 'Product';
  @override String get category => 'Category';
  @override String get currentStock => 'Current Stock';
  @override String get sellPrice => 'Sell Price (₹)';
  @override String get costPrice => 'Cost Price (₹)';
  @override String get revenueLabel => 'Revenue (₹)';
  @override String get estimatedProfit => 'Est. Profit (₹)';
  @override String get lastTxnDate => 'Last Txn Date';
  @override String get idLabel => 'ID';

  @override String get salesHistory => 'Sales History';
  @override String get dateLabel => 'Date';
  @override String get noSalesFound => 'No sales found';
  @override String get filterByDate => 'Filter by date';
  @override String get clearFilter => 'Clear filter';
  @override String get modeLabel => 'Mode';
  @override String get quantityLabel => 'Qty';
  @override String get totalLabel => 'Total';
  @override String get profitLabel => 'Profit';
  @override String get transactionsLabel => 'transactions';

  @override String get settings => 'Settings';
  @override String get account => 'Account';
  @override String get shopName => 'Shop Name';
  @override String get currency => 'Currency';
  @override String get notifications => 'Notifications';
  @override String get theme => 'Theme';
  @override String get language => 'Language';
  @override String get about => 'About';
  @override String get logout => 'Logout';
  @override String get selectLanguage => 'Select Language';
  @override String get selectCurrency => 'Select Currency';
  @override String get editShopName => 'Edit Shop Name';
  @override String get lowStockAlertsEnabled => 'Low-stock alerts enabled';
  @override String get alertsDisabled => 'Alerts disabled';
  @override String get darkTheme => 'Dark';
  @override String get lightTheme => 'Light';
  @override String get notificationsEnabledMsg => 'Notifications enabled';
  @override String get notificationsDisabledMsg => 'Notifications disabled';
  @override String get darkThemeMsg => 'Dark theme selected (visual change coming soon)';
  @override String get lightThemeMsg => 'Light theme selected';
  @override String get shopNameUpdated => 'Shop name updated';
  @override String get accountDetails => 'Account Details';
  @override String get nameLabel => 'Name';
  @override String get providerLabel => 'Provider(s)';
  @override String get createdLabel => 'Created';
  @override String get deleteAccount => 'Delete Account';
  @override String get thisWillDelete => 'This will permanently delete:';
  @override String get deleteItemCredentials => 'Your account and login credentials';
  @override String get deleteItemShopSettings => 'Shop name, avatar, and all settings';
  @override String get deleteItemLocalData => 'All locally stored data';
  @override String get cannotBeUndone => 'This action cannot be undone.';
  @override String get typeDeleteToConfirm => 'Type DELETE to confirm:';
  @override String get deletePermanently => 'Delete Permanently';
  @override String get notSignedIn => 'Not signed in';
  @override String get aboutVersion => 'GrowthOS v0.1.0';
  @override String get aboutDescription => 'AI-Powered Business Insights for Small Shop Owners.';

  @override String get addProduct => 'Add Product';
  @override String get recordSale => 'Record Sale';
  @override String get productNameLabel => 'Product Name';
  @override String get sellingPriceLabel => 'Selling Price (₹)';
  @override String get initialStock => 'Initial Stock';
  @override String get selectProduct => 'Select Product';
  @override String get transactionMode => 'Transaction Mode';
  @override String get productAddedSuccess => 'Product added successfully!';
  @override String get saleRecordedSuccess => 'Sale recorded successfully!';
  @override String get fieldRequired => 'This field is required';
  @override String get enterValidNumber => 'Enter a valid number';
  @override String get noProductsAvailable => 'No products available. Add products first.';
  @override String get addProductDesc => 'Fill in the details below to add a new product to your inventory.';
  @override String get recordSaleDesc => 'Select a product and enter sale details to record a transaction.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Hindi (हिन्दी)
// ─────────────────────────────────────────────────────────────────────────────

class _Hi extends _Strings {
  const _Hi();

  @override String get appName => 'GrowthOS';

  @override String get save => 'सहेजें';
  @override String get cancel => 'रद्द करें';
  @override String get close => 'बंद करें';
  @override String get ok => 'ठीक है';
  @override String get retry => 'पुनः प्रयास';
  @override String get back => 'वापस';
  @override String get next => 'अगला';
  @override String get delete => 'हटाएं';
  @override String get edit => 'संपादित करें';
  @override String get loading => 'लोड हो रहा है...';
  @override String get error => 'त्रुटि';
  @override String get success => 'सफलता';
  @override String get noData => 'कोई डेटा नहीं';
  @override String get notSet => 'सेट नहीं है';
  @override String get unknown => 'अज्ञात';

  @override String get navDashboard => 'डैशबोर्ड';
  @override String get navInventory => 'इन्वेंटरी';
  @override String get navSalesHistory => 'बिक्री इतिहास';
  @override String get navSettings => 'सेटिंग्स';

  @override String get loginTitle => 'अपने खाते में साइन इन करें';
  @override String get email => 'ईमेल';
  @override String get password => 'पासवर्ड';
  @override String get signIn => 'साइन इन';
  @override String get forgotPassword => 'पासवर्ड भूल गए?';
  @override String get orContinueWith => 'या इससे जारी रखें';
  @override String get continueWithGoogle => 'Google से जारी रखें';
  @override String get continueWithFacebook => 'Facebook से जारी रखें';
  @override String get dontHaveAccount => 'खाता नहीं है? साइन अप करें';
  @override String get phoneLabel => 'फ़ोन';
  @override String get phoneNumber => 'फ़ोन नंबर';
  @override String get sendOtp => 'OTP भेजें';
  @override String get enterOtp => '6-अंकीय OTP दर्ज करें';
  @override String get verifyOtp => 'OTP सत्यापित करें';
  @override String get emailRequired => 'ईमेल आवश्यक है';
  @override String get enterValidEmail => 'वैध ईमेल दर्ज करें';
  @override String get passwordRequired => 'पासवर्ड आवश्यक है';
  @override String get minSixChars => 'न्यूनतम 6 अक्षर';
  @override String get otpSent => 'आपके फ़ोन पर OTP भेजा गया';
  @override String get invalidOtp => 'वैध 6-अंकीय OTP दर्ज करें';
  @override String get signedInWithGoogle => 'Google से सफलतापूर्वक साइन इन!';
  @override String get signedInWithFacebook => 'Facebook से सफलतापूर्वक साइन इन!';
  @override String get requiresRecentLogin => 'सुरक्षा के लिए, कृपया साइन आउट करें, पुनः साइन इन करें और फिर कोशिश करें।';

  @override String get createAccount => 'खाता बनाएं';
  @override String get fullName => 'पूरा नाम';
  @override String get confirmPassword => 'पासवर्ड की पुष्टि करें';
  @override String get signUp => 'साइन अप';
  @override String get alreadyHaveAccount => 'पहले से खाता है? साइन इन करें';
  @override String get joinGrowthOS => 'GrowthOS से जुड़ें';
  @override String get nameRequired => 'नाम आवश्यक है';
  @override String get confirmPasswordRequired => 'पासवर्ड की पुष्टि करें';
  @override String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';
  @override String get orSignUpWith => 'या साइन अप करें';
  @override String get resetPassword => 'पासवर्ड रीसेट करें';
  @override String get resetPasswordDesc => 'अपना पंजीकृत ईमेल दर्ज करें और हम आपको पासवर्ड रीसेट करने का लिंक भेजेंगे।';
  @override String get sendResetLink => 'रीसेट लिंक भेजें';
  @override String get backToLogin => 'लॉगिन पर वापस जाएं';
  @override String get checkYourEmail => 'अपना ईमेल जांचें';
  @override String get emailSentDesc => 'हमने आपके ईमेल पर पासवर्ड रीसेट लिंक भेजा है। नया पासवर्ड सेट करने के लिए ईमेल में लिंक पर क्लिक करें।';
  @override String get backToSignIn => 'साइन इन पर वापस जाएं';
  @override String get didntReceiveEmail => 'ईमेल नहीं मिला? ';
  @override String get resend => 'पुनः भेजें';
  @override String get checkSpamTip => 'यदि ईमेल नहीं दिखे तो स्पैम/जंक फ़ोल्डर देखें। लिंक 1 घंटे में समाप्त हो जाता है।';
  @override String get stepEmailSent => 'ईमेल भेजा गया';
  @override String get stepClickLink => 'लिंक पर क्लिक करें';
  @override String get stepNewPassword => 'नया पासवर्ड';
  @override String resendInSeconds(int s) => '${s}s में पुनः भेजें';

  @override String get letsSetupStore => 'आइए अपनी दुकान सेट करें';
  @override String get whatsYourName => 'आपका नाम क्या है?';
  @override String get nameDisplayedProfile => 'यह आपकी प्रोफ़ाइल पर दिखाया जाएगा';
  @override String get nameYourShop => 'अपनी दुकान का नाम दें';
  @override String get shopNameDisplayed => 'यह आपके साइडबार और डैशबोर्ड पर दिखेगा';
  @override String get chooseProfileIcon => 'प्रोफ़ाइल आइकन चुनें';
  @override String get getStarted => 'शुरू करें';
  @override String get skipForNow => 'अभी छोड़ें';
  @override String get yourName => 'आपका नाम';
  @override String get shopNameLabel => 'दुकान का नाम';
  @override String get profileLabel => 'प्रोफ़ाइल';
  @override String get pleaseEnterName => 'कृपया अपना नाम दर्ज करें';
  @override String get pleaseEnterShopName => 'कृपया अपनी दुकान का नाम दर्ज करें';
  @override String get pickIconHint => 'अपनी दुकान के लिए एक आइकन चुनें';
  @override String get pickIconHintWithPhoto => 'आपकी Google/Facebook फ़ोटो पहले से सेट है। बदलने के लिए आइकन चुनें।';

  @override String get totalSales => 'कुल बिक्री';
  @override String get totalProfit => 'कुल लाभ';
  @override String get unitsSold => 'बेची गई इकाइयां';
  @override String get lowStockCount => 'कम स्टॉक';
  @override String get topProducts => 'शीर्ष उत्पाद';
  @override String get salesTrend => 'बिक्री ट्रेंड';
  @override String get aiInsights => 'AI अंतर्दृष्टि';
  @override String get errorLoadingDashboard => 'डैशबोर्ड लोड करने में त्रुटि';
  @override String get lowStockProducts => 'कम स्टॉक उत्पाद';
  @override String get stockLabel => 'स्टॉक';

  @override String get inventory => 'इन्वेंटरी';
  @override String get productsLabel => 'उत्पाद';
  @override String get product => 'उत्पाद';
  @override String get category => 'श्रेणी';
  @override String get currentStock => 'वर्तमान स्टॉक';
  @override String get sellPrice => 'बिक्री मूल्य (₹)';
  @override String get costPrice => 'लागत मूल्य (₹)';
  @override String get revenueLabel => 'राजस्व (₹)';
  @override String get estimatedProfit => 'अनुमानित लाभ (₹)';
  @override String get lastTxnDate => 'अंतिम लेनदेन तिथि';
  @override String get idLabel => 'आईडी';

  @override String get salesHistory => 'बिक्री इतिहास';
  @override String get dateLabel => 'तिथि';
  @override String get noSalesFound => 'कोई बिक्री नहीं मिली';
  @override String get filterByDate => 'तिथि के अनुसार फ़िल्टर';
  @override String get clearFilter => 'फ़िल्टर हटाएं';
  @override String get modeLabel => 'माध्यम';
  @override String get quantityLabel => 'मात्रा';
  @override String get totalLabel => 'कुल';
  @override String get profitLabel => 'लाभ';
  @override String get transactionsLabel => 'लेनदेन';

  @override String get settings => 'सेटिंग्स';
  @override String get account => 'खाता';
  @override String get shopName => 'दुकान का नाम';
  @override String get currency => 'मुद्रा';
  @override String get notifications => 'सूचनाएं';
  @override String get theme => 'थीम';
  @override String get language => 'भाषा';
  @override String get about => 'जानकारी';
  @override String get logout => 'लॉगआउट';
  @override String get selectLanguage => 'भाषा चुनें';
  @override String get selectCurrency => 'मुद्रा चुनें';
  @override String get editShopName => 'दुकान का नाम बदलें';
  @override String get lowStockAlertsEnabled => 'कम स्टॉक अलर्ट सक्षम';
  @override String get alertsDisabled => 'अलर्ट अक्षम';
  @override String get darkTheme => 'डार्क';
  @override String get lightTheme => 'लाइट';
  @override String get notificationsEnabledMsg => 'सूचनाएं सक्षम';
  @override String get notificationsDisabledMsg => 'सूचनाएं अक्षम';
  @override String get darkThemeMsg => 'डार्क थीम चुनी गई (जल्द आएगा)';
  @override String get lightThemeMsg => 'लाइट थीम चुनी गई';
  @override String get shopNameUpdated => 'दुकान का नाम अपडेट हुआ';
  @override String get accountDetails => 'खाता विवरण';
  @override String get nameLabel => 'नाम';
  @override String get providerLabel => 'प्रदाता';
  @override String get createdLabel => 'बनाया गया';
  @override String get deleteAccount => 'खाता हटाएं';
  @override String get thisWillDelete => 'यह हमेशा के लिए हटा देगा:';
  @override String get deleteItemCredentials => 'आपका खाता और लॉगिन क्रेडेंशियल';
  @override String get deleteItemShopSettings => 'दुकान का नाम, अवतार और सभी सेटिंग्स';
  @override String get deleteItemLocalData => 'सभी स्थानीय रूप से संग्रहीत डेटा';
  @override String get cannotBeUndone => 'यह क्रिया पूर्ववत नहीं की जा सकती।';
  @override String get typeDeleteToConfirm => 'पुष्टि के लिए DELETE टाइप करें:';
  @override String get deletePermanently => 'स्थायी रूप से हटाएं';
  @override String get notSignedIn => 'साइन इन नहीं है';
  @override String get aboutVersion => 'GrowthOS v0.1.0';
  @override String get aboutDescription => 'छोटे दुकानदारों के लिए AI-संचालित व्यापार अंतर्दृष्टि।';

  @override String get addProduct => 'उत्पाद जोड़ें';
  @override String get recordSale => 'बिक्री दर्ज करें';
  @override String get productNameLabel => 'उत्पाद का नाम';
  @override String get sellingPriceLabel => 'बिक्री मूल्य (₹)';
  @override String get initialStock => 'प्रारंभिक स्टॉक';
  @override String get selectProduct => 'उत्पाद चुनें';
  @override String get transactionMode => 'भुगतान माध्यम';
  @override String get productAddedSuccess => 'उत्पाद सफलतापूर्वक जोड़ा गया!';
  @override String get saleRecordedSuccess => 'बिक्री सफलतापूर्वक दर्ज हुई!';
  @override String get fieldRequired => 'यह फ़ील्ड आवश्यक है';
  @override String get enterValidNumber => 'एक वैध संख्या दर्ज करें';
  @override String get noProductsAvailable => 'कोई उत्पाद उपलब्ध नहीं है। पहले उत्पाद जोड़ें।';
  @override String get addProductDesc => 'अपनी इन्वेंटरी में नया उत्पाद जोड़ने के लिए नीचे विवरण भरें।';
  @override String get recordSaleDesc => 'लेनदेन दर्ज करने के लिए उत्पाद चुनें और बिक्री विवरण दर्ज करें।';
}

class _Ta extends _Strings {
  const _Ta();

  @override String get appName => 'GrowthOS';

  @override String get save => 'சேமி';
  @override String get cancel => 'ரத்து செய்';
  @override String get close => 'மூடு';
  @override String get ok => 'சரி';
  @override String get retry => 'மீண்டும் முயற்சி';
  @override String get back => 'பின்';
  @override String get next => 'அடுத்து';
  @override String get delete => 'நீக்கு';
  @override String get edit => 'திருத்து';
  @override String get loading => 'ஏற்றுகிறது...';
  @override String get error => 'பிழை';
  @override String get success => 'வெற்றி';
  @override String get noData => 'தரவு இல்லை';
  @override String get notSet => 'அமைக்கப்படவில்லை';
  @override String get unknown => 'தெரியாத';

  @override String get navDashboard => 'டாஷ்போர்டு';
  @override String get navInventory => 'சரக்கு';
  @override String get navSalesHistory => 'விற்பனை வரலாறு';
  @override String get navSettings => 'அமைப்புகள்';

  @override String get loginTitle => 'உங்கள் கணக்கில் உள்நுழைக';
  @override String get email => 'மின்னஞ்சல்';
  @override String get password => 'கடவுச்சொல்';
  @override String get signIn => 'உள்நுழை';
  @override String get forgotPassword => 'கடவுச்சொல் மறந்தீர்களா?';
  @override String get orContinueWith => 'அல்லது தொடரவும்';
  @override String get continueWithGoogle => 'Google மூலம் தொடரவும்';
  @override String get continueWithFacebook => 'Facebook மூலம் தொடரவும்';
  @override String get dontHaveAccount => 'கணக்கு இல்லையா? பதிவு செய்க';
  @override String get phoneLabel => 'தொலைபேசி';
  @override String get phoneNumber => 'தொலைபேசி எண்';
  @override String get sendOtp => 'OTP அனுப்பு';
  @override String get enterOtp => '6 இலக்க OTP உள்ளிடவும்';
  @override String get verifyOtp => 'OTP சரிபார்';
  @override String get emailRequired => 'மின்னஞ்சல் தேவை';
  @override String get enterValidEmail => 'சரியான மின்னஞ்சல் உள்ளிடவும்';
  @override String get passwordRequired => 'கடவுச்சொல் தேவை';
  @override String get minSixChars => 'குறைந்தது 6 எழுத்துகள்';
  @override String get otpSent => 'உங்கள் தொலைபேசிக்கு OTP அனுப்பப்பட்டது';
  @override String get invalidOtp => 'சரியான 6 இலக்க OTP உள்ளிடவும்';
  @override String get signedInWithGoogle => 'Google மூலம் வெற்றிகரமாக உள்நுழைந்தீர்கள்!';
  @override String get signedInWithFacebook => 'Facebook மூலம் வெற்றிகரமாக உள்நுழைந்தீர்கள்!';
  @override String get requiresRecentLogin => 'பாதுகாப்பிற்காக, வெளியேறி மீண்டும் உள்நுழைந்து முயற்சிக்கவும்.';

  @override String get createAccount => 'கணக்கு உருவாக்கு';
  @override String get fullName => 'முழு பெயர்';
  @override String get confirmPassword => 'கடவுச்சொல் உறுதிப்படுத்து';
  @override String get signUp => 'பதிவு செய்';
  @override String get alreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழைக';
  @override String get joinGrowthOS => 'GrowthOS இல் சேருங்கள்';
  @override String get nameRequired => 'பெயர் தேவை';
  @override String get confirmPasswordRequired => 'கடவுச்சொல்லை உறுதிப்படுத்துங்கள்';
  @override String get passwordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';
  @override String get orSignUpWith => 'அல்லது இதன் மூலம் பதிவு செய்யுங்கள்';
  @override String get resetPassword => 'கடவுச்சொல் மீட்டமை';
  @override String get resetPasswordDesc => 'உங்கள் பதிவு செய்த மின்னஞ்சலை உள்ளிடுங்கள், நாங்கள் கடவுச்சொல் மீட்டமைக்க இணைப்பு அனுப்புவோம்.';
  @override String get sendResetLink => 'மீட்டமைப்பு இணைப்பு அனுப்பு';
  @override String get backToLogin => 'உள்நுழைவுக்கு திரும்பு';
  @override String get checkYourEmail => 'உங்கள் மின்னஞ்சலைப் பார்க்கவும்';
  @override String get emailSentDesc => 'உங்கள் மின்னஞ்சலுக்கு கடவுச்சொல் மீட்டமைப்பு இணைப்பு அனுப்பப்பட்டது. புதிய கடவுச்சொல் அமைக்க இணைப்பை கிளிக் செய்யுங்கள்.';
  @override String get backToSignIn => 'உள்நுழைவுக்கு திரும்பு';
  @override String get didntReceiveEmail => 'மின்னஞ்சல் வரவில்லையா? ';
  @override String get resend => 'மீண்டும் அனுப்பு';
  @override String get checkSpamTip => 'மின்னஞ்சல் தெரியவில்லை என்றால் ஸ்பாம்/ஜங்க் கோப்பகத்தை சரிபாருங்கள். இணைப்பு 1 மணி நேரத்தில் காலாவதியாகும்.';
  @override String get stepEmailSent => 'மின்னஞ்சல் அனுப்பப்பட்டது';
  @override String get stepClickLink => 'இணைப்பை கிளிக் செய்யுங்கள்';
  @override String get stepNewPassword => 'புதிய கடவுச்சொல்';
  @override String resendInSeconds(int s) => '${s}s இல் மீண்டும் அனுப்பு';

  @override String get letsSetupStore => 'உங்கள் கடையை அமைக்கலாம்';
  @override String get whatsYourName => 'உங்கள் பெயர் என்ன?';
  @override String get nameDisplayedProfile => 'இது உங்கள் சுயவிவரத்தில் காட்டப்படும்';
  @override String get nameYourShop => 'உங்கள் கடைக்கு பெயரிடுங்கள்';
  @override String get shopNameDisplayed => 'இது உங்கள் பக்கப்பட்டையிலும் டாஷ்போர்டிலும் தோன்றும்';
  @override String get chooseProfileIcon => 'சுயவிவர படவுரு தேர்வு செய்க';
  @override String get getStarted => 'தொடங்குங்கள்';
  @override String get skipForNow => 'இப்போது தவிர்';
  @override String get yourName => 'உங்கள் பெயர்';
  @override String get shopNameLabel => 'கடை பெயர்';
  @override String get profileLabel => 'சுயவிவரம்';
  @override String get pleaseEnterName => 'உங்கள் பெயரை உள்ளிடவும்';
  @override String get pleaseEnterShopName => 'கடையின் பெயரை உள்ளிடவும்';
  @override String get pickIconHint => 'உங்கள் கடைக்கு ஒரு படவுருவை தேர்ந்தெடுக்கவும்';
  @override String get pickIconHintWithPhoto => 'உங்கள் Google/Facebook படம் ஏற்கனவே உள்ளது. மாற்ற படவுரு தேர்க.';

  @override String get totalSales => 'மொத்த விற்பனை';
  @override String get totalProfit => 'மொத்த லாபம்';
  @override String get unitsSold => 'விற்கப்பட்ட அலகுகள்';
  @override String get lowStockCount => 'குறைந்த சரக்கு';
  @override String get topProducts => 'முதன்மை தயாரிப்புகள்';
  @override String get salesTrend => 'விற்பனை போக்கு';
  @override String get aiInsights => 'AI நுண்ணறிவு';
  @override String get errorLoadingDashboard => 'டாஷ்போர்டு ஏற்றுவதில் பிழை';
  @override String get lowStockProducts => 'குறைந்த சரக்கு தயாரிப்புகள்';
  @override String get stockLabel => 'சரக்கு';

  @override String get inventory => 'சரக்கு';
  @override String get productsLabel => 'தயாரிப்புகள்';
  @override String get product => 'தயாரிப்பு';
  @override String get category => 'வகை';
  @override String get currentStock => 'தற்போதைய சரக்கு';
  @override String get sellPrice => 'விற்பனை விலை (₹)';
  @override String get costPrice => 'செலவு விலை (₹)';
  @override String get revenueLabel => 'வருவாய் (₹)';
  @override String get estimatedProfit => 'மதிப்பிடப்பட்ட லாபம் (₹)';
  @override String get lastTxnDate => 'கடைசி பரிவர்த்தனை தேதி';
  @override String get idLabel => 'ஐடி';

  @override String get salesHistory => 'விற்பனை வரலாறு';
  @override String get dateLabel => 'தேதி';
  @override String get noSalesFound => 'விற்பனை எதுவும் இல்லை';
  @override String get filterByDate => 'தேதி வாரியாக வடிகட்டு';
  @override String get clearFilter => 'வடிகட்டியை அழி';
  @override String get modeLabel => 'முறை';
  @override String get quantityLabel => 'அளவு';
  @override String get totalLabel => 'மொத்தம்';
  @override String get profitLabel => 'லாபம்';
  @override String get transactionsLabel => 'பரிவர்த்தனைகள்';

  @override String get settings => 'அமைப்புகள்';
  @override String get account => 'கணக்கு';
  @override String get shopName => 'கடை பெயர்';
  @override String get currency => 'நாணயம்';
  @override String get notifications => 'அறிவிப்புகள்';
  @override String get theme => 'தீம்';
  @override String get language => 'மொழி';
  @override String get about => 'பற்றி';
  @override String get logout => 'வெளியேறு';
  @override String get selectLanguage => 'மொழி தேர்வு செய்க';
  @override String get selectCurrency => 'நாணயம் தேர்வு செய்க';
  @override String get editShopName => 'கடை பெயர் திருத்து';
  @override String get lowStockAlertsEnabled => 'குறைந்த சரக்கு எச்சரிக்கைகள் இயக்கப்பட்டது';
  @override String get alertsDisabled => 'எச்சரிக்கைகள் முடக்கப்பட்டது';
  @override String get darkTheme => 'இருண்ட';
  @override String get lightTheme => 'வெளிச்சமான';
  @override String get notificationsEnabledMsg => 'அறிவிப்புகள் இயக்கப்பட்டது';
  @override String get notificationsDisabledMsg => 'அறிவிப்புகள் முடக்கப்பட்டது';
  @override String get darkThemeMsg => 'இருண்ட தீம் தேர்ந்தெடுக்கப்பட்டது (விரைவில்)';
  @override String get lightThemeMsg => 'வெளிச்சமான தீம் தேர்ந்தெடுக்கப்பட்டது';
  @override String get shopNameUpdated => 'கடை பெயர் புதுப்பிக்கப்பட்டது';
  @override String get accountDetails => 'கணக்கு விவரங்கள்';
  @override String get nameLabel => 'பெயர்';
  @override String get providerLabel => 'வழங்குநர்';
  @override String get createdLabel => 'உருவாக்கப்பட்டது';
  @override String get deleteAccount => 'கணக்கை நீக்கு';
  @override String get thisWillDelete => 'இது நிரந்தரமாக நீக்கும்:';
  @override String get deleteItemCredentials => 'உங்கள் கணக்கு மற்றும் உள்நுழைவு நற்சான்றிதழ்கள்';
  @override String get deleteItemShopSettings => 'கடை பெயர், அவதார் மற்றும் அனைத்து அமைப்புகள்';
  @override String get deleteItemLocalData => 'உள்ளூரில் சேமிக்கப்பட்ட அனைத்து தரவும்';
  @override String get cannotBeUndone => 'இந்த செயலை மீட்டெடுக்க முடியாது.';
  @override String get typeDeleteToConfirm => 'உறுதிப்படுத்த DELETE என்று தட்டச்சு செய்க:';
  @override String get deletePermanently => 'நிரந்தரமாக நீக்கு';
  @override String get notSignedIn => 'உள்நுழையவில்லை';
  @override String get aboutVersion => 'GrowthOS v0.1.0';
  @override String get aboutDescription => 'சிறு கடையாளர்களுக்கான AI-இயக்கப்படும் வணிக நுண்ணறிவு.';

  @override String get addProduct => 'தயாரிப்பு சேர்';
  @override String get recordSale => 'விற்பனை பதிவு செய்';
  @override String get productNameLabel => 'தயாரிப்பு பெயர்';
  @override String get sellingPriceLabel => 'விற்பனை விலை (₹)';
  @override String get initialStock => 'ஆரம்ப சரக்கு';
  @override String get selectProduct => 'தயாரிப்பு தேர்வு செய்க';
  @override String get transactionMode => 'பரிவர்த்தனை முறை';
  @override String get productAddedSuccess => 'தயாரிப்பு வெற்றிகரமாக சேர்க்கப்பட்டது!';
  @override String get saleRecordedSuccess => 'விற்பனை வெற்றிகரமாக பதிவு செய்யப்பட்டது!';
  @override String get fieldRequired => 'இந்தப் புலம் தேவை';
  @override String get enterValidNumber => 'சரியான எண்ணை உள்ளிடவும்';
  @override String get noProductsAvailable => 'தயாரிப்புகள் இல்லை. முதலில் தயாரிப்புகளைச் சேருங்கள்.';
  @override String get addProductDesc => 'உங்கள் சரக்குக்கு புதிய தயாரிப்பு சேர்க்க கீழே விவரங்களை நிரப்பவும்.';
  @override String get recordSaleDesc => 'பரிவர்த்தனை பதிவு செய்ய தயாரிப்பைத் தேர்ந்தெடுத்து விற்பனை விவரங்களை உள்ளிடவும்.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Marathi (मराठी)
// ─────────────────────────────────────────────────────────────────────────────

class _Mr extends _Strings {
  const _Mr();

  @override String get appName => 'GrowthOS';

  @override String get save => 'जतन करा';
  @override String get cancel => 'रद्द करा';
  @override String get close => 'बंद करा';
  @override String get ok => 'ठीक आहे';
  @override String get retry => 'पुन्हा प्रयत्न';
  @override String get back => 'मागे';
  @override String get next => 'पुढे';
  @override String get delete => 'हटवा';
  @override String get edit => 'संपादित करा';
  @override String get loading => 'लोड होत आहे...';
  @override String get error => 'त्रुटी';
  @override String get success => 'यशस्वी';
  @override String get noData => 'डेटा नाही';
  @override String get notSet => 'सेट केलेले नाही';
  @override String get unknown => 'अज्ञात';

  @override String get navDashboard => 'डॅशबोर्ड';
  @override String get navInventory => 'यादी';
  @override String get navSalesHistory => 'विक्री इतिहास';
  @override String get navSettings => 'सेटिंग्ज';

  @override String get loginTitle => 'आपल्या खात्यात साइन इन करा';
  @override String get email => 'ईमेल';
  @override String get password => 'पासवर्ड';
  @override String get signIn => 'साइन इन';
  @override String get forgotPassword => 'पासवर्ड विसरलात?';
  @override String get orContinueWith => 'किंवा यासह सुरू ठेवा';
  @override String get continueWithGoogle => 'Google सोबत सुरू ठेवा';
  @override String get continueWithFacebook => 'Facebook सोबत सुरू ठेवा';
  @override String get dontHaveAccount => 'खाते नाही? साइन अप करा';
  @override String get phoneLabel => 'फोन';
  @override String get phoneNumber => 'फोन नंबर';
  @override String get sendOtp => 'OTP पाठवा';
  @override String get enterOtp => '6-अंकी OTP प्रविष्ट करा';
  @override String get verifyOtp => 'OTP सत्यापित करा';
  @override String get emailRequired => 'ईमेल आवश्यक आहे';
  @override String get enterValidEmail => 'वैध ईमेल प्रविष्ट करा';
  @override String get passwordRequired => 'पासवर्ड आवश्यक आहे';
  @override String get minSixChars => 'किमान 6 वर्णे';
  @override String get otpSent => 'आपल्या फोनवर OTP पाठवला';
  @override String get invalidOtp => 'वैध 6-अंकी OTP प्रविष्ट करा';
  @override String get signedInWithGoogle => 'Google सोबत यशस्वीरित्या साइन इन!';
  @override String get signedInWithFacebook => 'Facebook सोबत यशस्वीरित्या साइन इन!';
  @override String get requiresRecentLogin => 'सुरक्षिततेसाठी, कृपया साइन आउट करा, पुन्हा साइन इन करा आणि प्रयत्न करा.';

  @override String get createAccount => 'खाते तयार करा';
  @override String get fullName => 'पूर्ण नाव';
  @override String get confirmPassword => 'पासवर्डची पुष्टी करा';
  @override String get signUp => 'साइन अप';
  @override String get alreadyHaveAccount => 'आधीच खाते आहे? साइन इन करा';
  @override String get joinGrowthOS => 'GrowthOS मध्ये सामील व्हा';
  @override String get nameRequired => 'नाव आवश्यक आहे';
  @override String get confirmPasswordRequired => 'पासवर्ड नक्की करा';
  @override String get passwordsDoNotMatch => 'पासवर्ड जुळत नाहीत';
  @override String get orSignUpWith => 'किंवा याद्वारे साइन अप करा';
  @override String get resetPassword => 'पासवर्ड रीसेट करा';
  @override String get resetPasswordDesc => 'तुमचा नोंदणीकृत ईमेल प्रविष्ट करा, आम्ही तुम्हाला पासवर्ड रीसेट करण्यासाठी लिंक पाठवू.';
  @override String get sendResetLink => 'रीसेट लिंक पाठवा';
  @override String get backToLogin => 'लॉगिनकडे परत जा';
  @override String get checkYourEmail => 'तुमचा ईमेल तपासा';
  @override String get emailSentDesc => 'आम्ही तुमच्या ईमेलवर पासवर्ड रीसेट लिंक पाठवला आहे. नवीन पासवर्ड सेट करण्यासाठी ईमेलमधील लिंकवर क्लिक करा.';
  @override String get backToSignIn => 'साइन इनकडे परत जा';
  @override String get didntReceiveEmail => 'ईमेल मिळाला नाही? ';
  @override String get resend => 'पुन्हा पाठवा';
  @override String get checkSpamTip => 'ईमेल दिसत नसल्यास स्पॅम/जंक फोल्डर तपासा. लिंक 1 तासात कालबाह्य होतो.';
  @override String get stepEmailSent => 'ईमेल पाठवला';
  @override String get stepClickLink => 'लिंकवर क्लिक करा';
  @override String get stepNewPassword => 'नवीन पासवर्ड';
  @override String resendInSeconds(int s) => '${s}s मध्ये पुन्हा पाठवा';

  @override String get letsSetupStore => 'आपले दुकान सेट करूया';
  @override String get whatsYourName => 'आपले नाव काय आहे?';
  @override String get nameDisplayedProfile => 'हे आपल्या प्रोफाइलवर दर्शवले जाईल';
  @override String get nameYourShop => 'आपल्या दुकानाला नाव द्या';
  @override String get shopNameDisplayed => 'हे आपल्या साइडबार आणि डॅशबोर्डवर दिसेल';
  @override String get chooseProfileIcon => 'प्रोफाइल चिन्ह निवडा';
  @override String get getStarted => 'सुरू करा';
  @override String get skipForNow => 'आत्तासाठी वगळा';
  @override String get yourName => 'आपले नाव';
  @override String get shopNameLabel => 'दुकानाचे नाव';
  @override String get profileLabel => 'प्रोफाइल';
  @override String get pleaseEnterName => 'कृपया आपले नाव प्रविष्ट करा';
  @override String get pleaseEnterShopName => 'कृपया आपल्या दुकानाचे नाव प्रविष्ट करा';
  @override String get pickIconHint => 'आपल्या दुकानासाठी एक चिन्ह निवडा';
  @override String get pickIconHintWithPhoto => 'आपला Google/Facebook फोटो आधीच सेट आहे. बदलण्यासाठी चिन्ह निवडा.';

  @override String get totalSales => 'एकूण विक्री';
  @override String get totalProfit => 'एकूण नफा';
  @override String get unitsSold => 'विकलेल्या वस्तू';
  @override String get lowStockCount => 'कमी साठा';
  @override String get topProducts => 'शीर्ष उत्पादने';
  @override String get salesTrend => 'विक्री ट्रेंड';
  @override String get aiInsights => 'AI अंतर्दृष्टी';
  @override String get errorLoadingDashboard => 'डॅशबोर्ड लोड करण्यात त्रुटी';
  @override String get lowStockProducts => 'कमी साठा उत्पादने';
  @override String get stockLabel => 'साठा';

  @override String get inventory => 'यादी';
  @override String get productsLabel => 'उत्पादने';
  @override String get product => 'उत्पादन';
  @override String get category => 'श्रेणी';
  @override String get currentStock => 'सद्य साठा';
  @override String get sellPrice => 'विक्री किंमत (₹)';
  @override String get costPrice => 'खर्च किंमत (₹)';
  @override String get revenueLabel => 'महसूल (₹)';
  @override String get estimatedProfit => 'अंदाजे नफा (₹)';
  @override String get lastTxnDate => 'शेवटची व्यवहार तारीख';
  @override String get idLabel => 'आयडी';

  @override String get salesHistory => 'विक्री इतिहास';
  @override String get dateLabel => 'तारीख';
  @override String get noSalesFound => 'विक्री आढळली नाही';
  @override String get filterByDate => 'तारखेनुसार फिल्टर';
  @override String get clearFilter => 'फिल्टर साफ करा';
  @override String get modeLabel => 'माध्यम';
  @override String get quantityLabel => 'प्रमाण';
  @override String get totalLabel => 'एकूण';
  @override String get profitLabel => 'नफा';
  @override String get transactionsLabel => 'व्यवहार';

  @override String get settings => 'सेटिंग्ज';
  @override String get account => 'खाते';
  @override String get shopName => 'दुकानाचे नाव';
  @override String get currency => 'चलन';
  @override String get notifications => 'सूचना';
  @override String get theme => 'थीम';
  @override String get language => 'भाषा';
  @override String get about => 'माहिती';
  @override String get logout => 'बाहेर पडा';
  @override String get selectLanguage => 'भाषा निवडा';
  @override String get selectCurrency => 'चलन निवडा';
  @override String get editShopName => 'दुकानाचे नाव बदला';
  @override String get lowStockAlertsEnabled => 'कमी साठा सतर्कता सक्षम';
  @override String get alertsDisabled => 'सतर्कता अक्षम';
  @override String get darkTheme => 'गडद';
  @override String get lightTheme => 'उज्ज्वल';
  @override String get notificationsEnabledMsg => 'सूचना सक्षम केल्या';
  @override String get notificationsDisabledMsg => 'सूचना अक्षम केल्या';
  @override String get darkThemeMsg => 'गडद थीम निवडली (लवकरच येईल)';
  @override String get lightThemeMsg => 'उज्ज्वल थीम निवडली';
  @override String get shopNameUpdated => 'दुकानाचे नाव अपडेट झाले';
  @override String get accountDetails => 'खाते तपशील';
  @override String get nameLabel => 'नाव';
  @override String get providerLabel => 'प्रदाता';
  @override String get createdLabel => 'तयार केले';
  @override String get deleteAccount => 'खाते हटवा';
  @override String get thisWillDelete => 'हे कायमचे हटवेल:';
  @override String get deleteItemCredentials => 'आपले खाते आणि लॉगिन क्रेडेन्शियल';
  @override String get deleteItemShopSettings => 'दुकानाचे नाव, अवतार आणि सर्व सेटिंग्ज';
  @override String get deleteItemLocalData => 'सर्व स्थानिक पातळीवर साठवलेला डेटा';
  @override String get cannotBeUndone => 'ही क्रिया पूर्वपदावर आणता येत नाही.';
  @override String get typeDeleteToConfirm => 'पुष्टीसाठी DELETE टाइप करा:';
  @override String get deletePermanently => 'कायमचे हटवा';
  @override String get notSignedIn => 'साइन इन केलेले नाही';
  @override String get aboutVersion => 'GrowthOS v0.1.0';
  @override String get aboutDescription => 'लहान दुकानदारांसाठी AI-चालित व्यवसाय अंतर्दृष्टी.';

  @override String get addProduct => 'उत्पादन जोडा';
  @override String get recordSale => 'विक्री नोंदवा';
  @override String get productNameLabel => 'उत्पादनाचे नाव';
  @override String get sellingPriceLabel => 'विक्री किंमत (₹)';
  @override String get initialStock => 'प्रारंभिक साठा';
  @override String get selectProduct => 'उत्पादन निवडा';
  @override String get transactionMode => 'व्यवहार माध्यम';
  @override String get productAddedSuccess => 'उत्पादन यशस्वीरित्या जोडले!';
  @override String get saleRecordedSuccess => 'विक्री यशस्वीरित्या नोंदवली!';
  @override String get fieldRequired => 'हे फील्ड आवश्यक आहे';
  @override String get enterValidNumber => 'वैध संख्या प्रविष्ट करा';
  @override String get noProductsAvailable => 'उत्पादने उपलब्ध नाहीत. प्रथम उत्पादने जोडा.';
  @override String get addProductDesc => 'आपल्या यादीत नवीन उत्पादन जोडण्यासाठी खालील तपशील भरा.';
  @override String get recordSaleDesc => 'व्यवहार नोंदवण्यासाठी उत्पादन निवडा आणि विक्री तपशील प्रविष्ट करा.';
}
