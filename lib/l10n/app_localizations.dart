import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application name
  ///
  /// In ar, this message translates to:
  /// **'ATHAR - HR'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الموارد البشرية'**
  String get appTagline;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clear;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @submit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get submit;

  /// No description provided for @view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get view;

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get details;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @success.
  ///
  /// In ar, this message translates to:
  /// **'تم بنجاح'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In ar, this message translates to:
  /// **'معلومة'**
  String get info;

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get optional;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @from.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get to;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @time.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get time;

  /// No description provided for @month.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get month;

  /// No description provided for @year.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get year;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @type.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get type;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @actions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get actions;

  /// No description provided for @unknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get unknown;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get welcome;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تسجيل الخروج؟'**
  String get logoutConfirm;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح'**
  String get lightMode;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get version;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بياناتك للمتابعة'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'example@company.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @loginLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تسجيل الدخول...'**
  String get loginLoading;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صحيح'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 8 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @loginFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get loginFailed;

  /// No description provided for @wrongCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get wrongCredentials;

  /// No description provided for @accountDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الحساب معطل، تواصل مع المسؤول'**
  String get accountDisabled;

  /// No description provided for @tooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، حاول لاحقاً'**
  String get tooManyRequests;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني وسنرسل لك رابط الاستعادة'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط الاستعادة'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني'**
  String get resetLinkSent;

  /// No description provided for @backToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get backToLogin;

  /// No description provided for @emailNotFound.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير مسجل في النظام'**
  String get emailNotFound;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حدّث كلمة المرور المستخدمة لتسجيل الدخول'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In ar, this message translates to:
  /// **'تحديث كلمة المرور'**
  String get updatePassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة المرور بنجاح'**
  String get passwordUpdated;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية غير صحيحة'**
  String get currentPasswordIncorrect;

  /// No description provided for @recentLoginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تسجيل الدخول مرة أخرى قبل تحديث كلمة المرور'**
  String get recentLoginRequired;

  /// No description provided for @weakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة جداً'**
  String get weakPassword;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير النظام'**
  String get roleAdmin;

  /// No description provided for @roleSupervisor.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get roleSupervisor;

  /// No description provided for @roleEmployee.
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get roleEmployee;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminDashboard;

  /// No description provided for @supervisorDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المشرف'**
  String get supervisorDashboard;

  /// No description provided for @employeeDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحتي'**
  String get employeeDashboard;

  /// No description provided for @totalEmployees.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الموظفين'**
  String get totalEmployees;

  /// No description provided for @totalSupervisors.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشرفين'**
  String get totalSupervisors;

  /// No description provided for @totalCandidates.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي السيفيهات'**
  String get totalCandidates;

  /// No description provided for @todayAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضور اليوم'**
  String get todayAttendance;

  /// No description provided for @pendingLeaves.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الإجازة المعلقة'**
  String get pendingLeaves;

  /// No description provided for @recentActivity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط الأخير'**
  String get recentActivity;

  /// No description provided for @quickStats.
  ///
  /// In ar, this message translates to:
  /// **'إحصاءات سريعة'**
  String get quickStats;

  /// No description provided for @employees.
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get employees;

  /// No description provided for @employeeManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الموظفين'**
  String get employeeManagement;

  /// No description provided for @addEmployee.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموظف'**
  String get editEmployee;

  /// No description provided for @employeeName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموظف'**
  String get employeeName;

  /// No description provided for @employeeCode.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموظف'**
  String get employeeCode;

  /// No description provided for @department.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get department;

  /// No description provided for @position.
  ///
  /// In ar, this message translates to:
  /// **'المنصب'**
  String get position;

  /// No description provided for @hireDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التعيين'**
  String get hireDate;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @employeeDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الموظف'**
  String get employeeDetails;

  /// No description provided for @noEmployees.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون'**
  String get noEmployees;

  /// No description provided for @supervisors.
  ///
  /// In ar, this message translates to:
  /// **'المشرفون'**
  String get supervisors;

  /// No description provided for @supervisorManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المشرفين'**
  String get supervisorManagement;

  /// No description provided for @addSupervisor.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مشرف'**
  String get addSupervisor;

  /// No description provided for @noSupervisors.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مشرفون'**
  String get noSupervisors;

  /// No description provided for @candidates.
  ///
  /// In ar, this message translates to:
  /// **'السيفيهات'**
  String get candidates;

  /// No description provided for @candidateManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة السيفيهات'**
  String get candidateManagement;

  /// No description provided for @addCandidate.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سيفي'**
  String get addCandidate;

  /// No description provided for @editCandidate.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات السيفي'**
  String get editCandidate;

  /// No description provided for @candidateDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات السيفي'**
  String get candidateDetails;

  /// No description provided for @candidateProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملف السيفي'**
  String get candidateProfile;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @nationality.
  ///
  /// In ar, this message translates to:
  /// **'الجنسية'**
  String get nationality;

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age;

  /// No description provided for @religion.
  ///
  /// In ar, this message translates to:
  /// **'الديانة'**
  String get religion;

  /// No description provided for @maritalStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الاجتماعية'**
  String get maritalStatus;

  /// No description provided for @experience.
  ///
  /// In ar, this message translates to:
  /// **'الخبرة'**
  String get experience;

  /// No description provided for @spokenLanguages.
  ///
  /// In ar, this message translates to:
  /// **'اللغات'**
  String get spokenLanguages;

  /// No description provided for @jobType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العمل'**
  String get jobType;

  /// No description provided for @profileImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة السيفي'**
  String get profileImage;

  /// No description provided for @cvImageSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف السيفي'**
  String get cvImageSectionTitle;

  /// No description provided for @cvImageSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ارفع ملف السيفي كصورة أو PDF، أو صوّر ورقة السيفي بالكاميرا.'**
  String get cvImageSectionSubtitle;

  /// No description provided for @cvImagePlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لإضافة ملف السيفي'**
  String get cvImagePlaceholder;

  /// No description provided for @cvImageRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب إضافة ملف السيفي'**
  String get cvImageRequired;

  /// No description provided for @cvImageSourceTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة إضافة ملف السيفي'**
  String get cvImageSourceTitle;

  /// No description provided for @pickCvFromFiles.
  ///
  /// In ar, this message translates to:
  /// **'رفع من الملفات'**
  String get pickCvFromFiles;

  /// No description provided for @pickCvFromFilesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة أو PDF من ملفات الجهاز'**
  String get pickCvFromFilesSubtitle;

  /// No description provided for @pickCvFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get pickCvFromGallery;

  /// No description provided for @pickCvFromGallerySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة السيفي من معرض الصور'**
  String get pickCvFromGallerySubtitle;

  /// No description provided for @captureCvWithCamera.
  ///
  /// In ar, this message translates to:
  /// **'تصوير بالكاميرا'**
  String get captureCvWithCamera;

  /// No description provided for @captureCvWithCameraSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'التقط صورة جديدة للسيفي مباشرة'**
  String get captureCvWithCameraSubtitle;

  /// No description provided for @cvFileRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب إضافة ملف السيفي'**
  String get cvFileRequired;

  /// No description provided for @unsupportedCvFileType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الملف غير مدعوم. اختر صورة أو PDF'**
  String get unsupportedCvFileType;

  /// No description provided for @cvFileTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'حجم الملف أكبر من الحد المسموح'**
  String get cvFileTooLarge;

  /// No description provided for @cvFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف السيرة الذاتية'**
  String get cvFile;

  /// No description provided for @videoUrl.
  ///
  /// In ar, this message translates to:
  /// **'فيديو تعريفي'**
  String get videoUrl;

  /// No description provided for @assignedTo.
  ///
  /// In ar, this message translates to:
  /// **'مسند إلى'**
  String get assignedTo;

  /// No description provided for @reservedBy.
  ///
  /// In ar, this message translates to:
  /// **'محجوز بواسطة'**
  String get reservedBy;

  /// No description provided for @createdBy.
  ///
  /// In ar, this message translates to:
  /// **'أضيف بواسطة'**
  String get createdBy;

  /// No description provided for @assignCandidate.
  ///
  /// In ar, this message translates to:
  /// **'إسناد السيفي'**
  String get assignCandidate;

  /// No description provided for @noCandidates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سيفيهات'**
  String get noCandidates;

  /// No description provided for @searchCandidates.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في السيفيهات...'**
  String get searchCandidates;

  /// No description provided for @nationalityPhilippines.
  ///
  /// In ar, this message translates to:
  /// **'فلبينية'**
  String get nationalityPhilippines;

  /// No description provided for @nationalityKenya.
  ///
  /// In ar, this message translates to:
  /// **'كينية'**
  String get nationalityKenya;

  /// No description provided for @nationalityUganda.
  ///
  /// In ar, this message translates to:
  /// **'أوغندية'**
  String get nationalityUganda;

  /// No description provided for @nationalityEthiopia.
  ///
  /// In ar, this message translates to:
  /// **'إثيوبية'**
  String get nationalityEthiopia;

  /// No description provided for @nationalityBangladesh.
  ///
  /// In ar, this message translates to:
  /// **'بنغلاديشية'**
  String get nationalityBangladesh;

  /// No description provided for @statusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get statusNew;

  /// No description provided for @statusAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get statusAvailable;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusReserved.
  ///
  /// In ar, this message translates to:
  /// **'محجوز'**
  String get statusReserved;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @statusHired.
  ///
  /// In ar, this message translates to:
  /// **'تم التوظيف'**
  String get statusHired;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get statusCancelled;

  /// No description provided for @changeStatus.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحالة'**
  String get changeStatus;

  /// No description provided for @attendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get attendance;

  /// No description provided for @attendanceManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحضور'**
  String get attendanceManagement;

  /// No description provided for @checkIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحضور'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الانصراف'**
  String get checkOut;

  /// No description provided for @checkInTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الحضور'**
  String get checkInTime;

  /// No description provided for @checkOutTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الانصراف'**
  String get checkOutTime;

  /// No description provided for @attendanceHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحضور'**
  String get attendanceHistory;

  /// No description provided for @attendanceStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الحضور'**
  String get attendanceStatus;

  /// No description provided for @presentToday.
  ///
  /// In ar, this message translates to:
  /// **'حاضر اليوم'**
  String get presentToday;

  /// No description provided for @absentToday.
  ///
  /// In ar, this message translates to:
  /// **'غائب اليوم'**
  String get absentToday;

  /// No description provided for @lateToday.
  ///
  /// In ar, this message translates to:
  /// **'متأخر اليوم'**
  String get lateToday;

  /// No description provided for @latenessMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق التأخير'**
  String get latenessMinutes;

  /// No description provided for @shiftType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوردية'**
  String get shiftType;

  /// No description provided for @morningShift.
  ///
  /// In ar, this message translates to:
  /// **'الوردية الصباحية'**
  String get morningShift;

  /// No description provided for @eveningShift.
  ///
  /// In ar, this message translates to:
  /// **'الوردية المسائية'**
  String get eveningShift;

  /// No description provided for @insideGeofence.
  ///
  /// In ar, this message translates to:
  /// **'داخل النطاق الجغرافي'**
  String get insideGeofence;

  /// No description provided for @outsideGeofence.
  ///
  /// In ar, this message translates to:
  /// **'خارج النطاق الجغرافي'**
  String get outsideGeofence;

  /// No description provided for @locationRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب السماح بالوصول للموقع'**
  String get locationRequired;

  /// No description provided for @locationNotInZone.
  ///
  /// In ar, this message translates to:
  /// **'أنت خارج النطاق المسموح به'**
  String get locationNotInZone;

  /// No description provided for @gettingLocation.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحديد الموقع...'**
  String get gettingLocation;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تفعيل الموقع (GPS) من إعدادات الجهاز'**
  String get locationServiceDisabled;

  /// No description provided for @checkInSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور بنجاح'**
  String get checkInSuccess;

  /// No description provided for @checkOutSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الانصراف بنجاح'**
  String get checkOutSuccess;

  /// No description provided for @alreadyCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'لقد سجلت حضورك مسبقاً'**
  String get alreadyCheckedIn;

  /// No description provided for @notCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل حضورك بعد'**
  String get notCheckedIn;

  /// No description provided for @noAttendance.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سجلات حضور'**
  String get noAttendance;

  /// No description provided for @attendancePresent.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get attendancePresent;

  /// No description provided for @attendanceAbsent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get attendanceAbsent;

  /// No description provided for @attendanceLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get attendanceLate;

  /// No description provided for @attendanceLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة'**
  String get attendanceLeave;

  /// No description provided for @attendanceHoliday.
  ///
  /// In ar, this message translates to:
  /// **'عطلة'**
  String get attendanceHoliday;

  /// No description provided for @leaves.
  ///
  /// In ar, this message translates to:
  /// **'الإجازات'**
  String get leaves;

  /// No description provided for @leaveManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الإجازات'**
  String get leaveManagement;

  /// No description provided for @leaveRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب إجازة'**
  String get leaveRequest;

  /// No description provided for @permissionRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب إذن'**
  String get permissionRequest;

  /// No description provided for @addLeaveRequest.
  ///
  /// In ar, this message translates to:
  /// **'تقديم طلب إجازة'**
  String get addLeaveRequest;

  /// No description provided for @addPermissionRequest.
  ///
  /// In ar, this message translates to:
  /// **'تقديم طلب إذن'**
  String get addPermissionRequest;

  /// No description provided for @leaveType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الإجازة'**
  String get leaveType;

  /// No description provided for @startDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النهاية'**
  String get endDate;

  /// No description provided for @reason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get reason;

  /// No description provided for @leaveStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get leaveStatus;

  /// No description provided for @adminNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة المدير'**
  String get adminNote;

  /// No description provided for @approve.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @pendingStatus.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get pendingStatus;

  /// No description provided for @approvedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get approvedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get rejectedStatus;

  /// No description provided for @noLeaves.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلبات إجازة'**
  String get noLeaves;

  /// No description provided for @leaveSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم تقديم الطلب بنجاح'**
  String get leaveSubmitted;

  /// No description provided for @leaveApproved.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول طلب الإجازة'**
  String get leaveApproved;

  /// No description provided for @leaveRejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض طلب الإجازة'**
  String get leaveRejected;

  /// No description provided for @leaveTypeAnnual.
  ///
  /// In ar, this message translates to:
  /// **'إجازة رسمية'**
  String get leaveTypeAnnual;

  /// No description provided for @leaveTypeSick.
  ///
  /// In ar, this message translates to:
  /// **'إجازة مرضية'**
  String get leaveTypeSick;

  /// No description provided for @leaveTypeEmergency.
  ///
  /// In ar, this message translates to:
  /// **'إجازة اضطرارية'**
  String get leaveTypeEmergency;

  /// No description provided for @leaveTypeUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'إجازة بدون راتب'**
  String get leaveTypeUnpaid;

  /// No description provided for @leaveTypePermission.
  ///
  /// In ar, this message translates to:
  /// **'إذن'**
  String get leaveTypePermission;

  /// No description provided for @emergencyLeaveMaxDaysHint.
  ///
  /// In ar, this message translates to:
  /// **'الإجازة الاضطرارية بحد أقصى 3 أيام متصلة'**
  String get emergencyLeaveMaxDaysHint;

  /// No description provided for @emergencyLeaveExceedsMax.
  ///
  /// In ar, this message translates to:
  /// **'الإجازة الاضطرارية لا يمكن أن تتجاوز 3 أيام'**
  String get emergencyLeaveExceedsMax;

  /// No description provided for @salary.
  ///
  /// In ar, this message translates to:
  /// **'الراتب'**
  String get salary;

  /// No description provided for @salaryManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الرواتب'**
  String get salaryManagement;

  /// No description provided for @basicSalary.
  ///
  /// In ar, this message translates to:
  /// **'الراتب الأساسي'**
  String get basicSalary;

  /// No description provided for @additions.
  ///
  /// In ar, this message translates to:
  /// **'الإضافات'**
  String get additions;

  /// No description provided for @deductions.
  ///
  /// In ar, this message translates to:
  /// **'الخصومات'**
  String get deductions;

  /// No description provided for @netSalary.
  ///
  /// In ar, this message translates to:
  /// **'صافي الراتب'**
  String get netSalary;

  /// No description provided for @salaryMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر الراتب'**
  String get salaryMonth;

  /// No description provided for @salaryDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الراتب'**
  String get salaryDetails;

  /// No description provided for @noSalary.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بيانات راتب'**
  String get noSalary;

  /// No description provided for @addSalary.
  ///
  /// In ar, this message translates to:
  /// **'إضافة راتب'**
  String get addSalary;

  /// No description provided for @editSalary.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الراتب'**
  String get editSalary;

  /// No description provided for @commission.
  ///
  /// In ar, this message translates to:
  /// **'العمولة'**
  String get commission;

  /// No description provided for @commissionManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العمولات'**
  String get commissionManagement;

  /// No description provided for @commissionAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ العمولة'**
  String get commissionAmount;

  /// No description provided for @commissionMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر العمولة'**
  String get commissionMonth;

  /// No description provided for @commissionDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العمولة'**
  String get commissionDetails;

  /// No description provided for @commissionType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العمولة'**
  String get commissionType;

  /// No description provided for @commissionRuleNone.
  ///
  /// In ar, this message translates to:
  /// **'بدون'**
  String get commissionRuleNone;

  /// No description provided for @commissionRuleFixed.
  ///
  /// In ar, this message translates to:
  /// **'ثابت'**
  String get commissionRuleFixed;

  /// No description provided for @commissionRulePercentage.
  ///
  /// In ar, this message translates to:
  /// **'نسبة'**
  String get commissionRulePercentage;

  /// No description provided for @commissionSourceManualAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'تعديل يدوي'**
  String get commissionSourceManualAdjustment;

  /// No description provided for @commissionSourcePerformance.
  ///
  /// In ar, this message translates to:
  /// **'أداء'**
  String get commissionSourcePerformance;

  /// No description provided for @commissionSourceCandidateConversion.
  ///
  /// In ar, this message translates to:
  /// **'تحويل مرشح'**
  String get commissionSourceCandidateConversion;

  /// No description provided for @noCommission.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عمولات'**
  String get noCommission;

  /// No description provided for @addCommission.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عمولة'**
  String get addCommission;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @reportsAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'التقارير والتحليلات'**
  String get reportsAnalytics;

  /// No description provided for @attendanceReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الحضور'**
  String get attendanceReport;

  /// No description provided for @leaveReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الإجازات'**
  String get leaveReport;

  /// No description provided for @salaryReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الرواتب'**
  String get salaryReport;

  /// No description provided for @candidateReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير السيفيهات'**
  String get candidateReport;

  /// No description provided for @appSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التطبيق'**
  String get appSettings;

  /// No description provided for @companySettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الشركة'**
  String get companySettings;

  /// No description provided for @companyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get companyName;

  /// No description provided for @companyLocations.
  ///
  /// In ar, this message translates to:
  /// **'مواقع الشركة'**
  String get companyLocations;

  /// No description provided for @addLocation.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موقع'**
  String get addLocation;

  /// No description provided for @locationName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموقع'**
  String get locationName;

  /// No description provided for @radius.
  ///
  /// In ar, this message translates to:
  /// **'نطاق الجغرافي (متر)'**
  String get radius;

  /// No description provided for @latitude.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول'**
  String get longitude;

  /// No description provided for @geofenceSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات النطاق الجغرافي'**
  String get geofenceSettings;

  /// No description provided for @workShifts.
  ///
  /// In ar, this message translates to:
  /// **'أوقات العمل'**
  String get workShifts;

  /// No description provided for @workScheduleSettings.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل والسماح بالتأخير'**
  String get workScheduleSettings;

  /// No description provided for @graceMinutesLabel.
  ///
  /// In ar, this message translates to:
  /// **'دقائق السماح بالتأخير'**
  String get graceMinutesLabel;

  /// No description provided for @shiftStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية الوردية'**
  String get shiftStart;

  /// No description provided for @shiftEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية الوردية'**
  String get shiftEnd;

  /// No description provided for @permissionsManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الصلاحيات'**
  String get permissionsManagement;

  /// No description provided for @notificationLeaveUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة طلب الإجازة'**
  String get notificationLeaveUpdate;

  /// No description provided for @notificationCvAssigned.
  ///
  /// In ar, this message translates to:
  /// **'تم إسناد سيفي جديد إليك'**
  String get notificationCvAssigned;

  /// No description provided for @notificationAttendanceReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بتسجيل الحضور'**
  String get notificationAttendanceReminder;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد إشعارات'**
  String get noNotifications;

  /// No description provided for @myProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملفي الشخصي'**
  String get myProfile;

  /// No description provided for @myAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضوري'**
  String get myAttendance;

  /// No description provided for @mySalary.
  ///
  /// In ar, this message translates to:
  /// **'راتبي'**
  String get mySalary;

  /// No description provided for @myCommission.
  ///
  /// In ar, this message translates to:
  /// **'عمولتي'**
  String get myCommission;

  /// No description provided for @myLeaves.
  ///
  /// In ar, this message translates to:
  /// **'إجازاتي'**
  String get myLeaves;

  /// No description provided for @myRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequests;

  /// No description provided for @errorGeneral.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get errorGeneral;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الاتصال بالإنترنت'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية للقيام بهذا الإجراء'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'البيانات المطلوبة غير موجودة'**
  String get errorNotFound;

  /// No description provided for @errorUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل رفع الملف'**
  String get errorUploadFailed;

  /// No description provided for @errorLocationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديد الموقع'**
  String get errorLocationFailed;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء'**
  String get confirmDeleteMessage;

  /// No description provided for @deleteSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف بنجاح'**
  String get deleteSuccess;

  /// No description provided for @saveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ بنجاح'**
  String get saveSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التحديث بنجاح'**
  String get updateSuccess;

  /// No description provided for @single.
  ///
  /// In ar, this message translates to:
  /// **'أعزب'**
  String get single;

  /// No description provided for @married.
  ///
  /// In ar, this message translates to:
  /// **'متزوج'**
  String get married;

  /// No description provided for @divorced.
  ///
  /// In ar, this message translates to:
  /// **'مطلق'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In ar, this message translates to:
  /// **'أرمل'**
  String get widowed;

  /// No description provided for @muslim.
  ///
  /// In ar, this message translates to:
  /// **'مسلم'**
  String get muslim;

  /// No description provided for @christian.
  ///
  /// In ar, this message translates to:
  /// **'مسيحي'**
  String get christian;

  /// No description provided for @hindu.
  ///
  /// In ar, this message translates to:
  /// **'هندوسي'**
  String get hindu;

  /// No description provided for @buddhist.
  ///
  /// In ar, this message translates to:
  /// **'بوذي'**
  String get buddhist;

  /// No description provided for @other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get other;

  /// No description provided for @yearsExperience.
  ///
  /// In ar, this message translates to:
  /// **'{years} سنوات خبرة'**
  String yearsExperience(int years);

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء النور'**
  String get greetingEvening;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get currency;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
