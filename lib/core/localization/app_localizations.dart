import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('ar'));
  }

  bool get isArabic => locale.languageCode == 'ar';

  String translate(
    String arabicSource, [
    Map<String, Object?> values = const {},
  ]) {
    var result = isArabic
        ? arabicSource
        : (_englishTranslations[arabicSource] ??
              _translateDynamicArabic(arabicSource) ??
              arabicSource);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return result;
  }
}

extension LocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String arabicSource, [Map<String, Object?> values = const {}]) =>
      l10n.translate(arabicSource, values);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, String> _englishTranslations = {
  'التالي': 'Next',
  'ابدأ الآن': 'Get started',
  'استشر أفضل الأطباء': 'Consult the best doctors',
  'تواصل مع نخبة من الأطباء المتخصصين في كافة\nالمجالات الطبية بكل سهولة ويسر من هاتفك.':
      'Connect with experienced specialists across all medical fields directly from your phone.',
  'احجز موعدك بضغطة زر': 'Book your appointment in one tap',
  'وداعاً للانتظار، اختر الوقت والتاريخ المناسبين لك\nواحجز موعدك فوراً.':
      'Skip the waiting. Choose the date and time that suit you and book instantly.',
  'ملفك الطبي في جيبك': 'Your medical record in your pocket',
  'تابع نتائج تحاليلك، وصفاتك الطبية، وتاريخك المرضي\nفي أي وقت ومن أي مكان.':
      'Access your test results, prescriptions, and medical history anytime, anywhere.',
  'حدد نوع حسابك': 'Choose your account type',
  'اختر المسار المناسب حتى نعرض لك تجربة مصممة لدورك داخل مركز العيادات.':
      'Choose the right role for an experience tailored to you.',
  'مريض': 'Patient',
  'طبيب': 'Doctor',
  'مساحتك الصحية الشخصية': 'Your personal health space',
  'احجز موعدك، تابع ملفك الطبي، وراجع نتائجك من مكان واحد.':
      'Book appointments, follow your medical record, and review results in one place.',
  'المتابعة كمريض': 'Continue as patient',
  'إدارة العيادة بذكاء': 'Manage your clinic efficiently',
  'نظم المواعيد، تابع المرضى، وادخل إلى الملفات الطبية بسرعة.':
      'Organize appointments, follow patients, and access medical records quickly.',
  'المتابعة كطبيب': 'Continue as doctor',
  'اسحب للمتابعة كمريض': 'Slide to continue as patient',
  'اسحب للمتابعة كطبيب': 'Slide to continue as doctor',
  'مواعيد': 'Appointments',
  'ملف طبي': 'Medical record',
  'تحاليل': 'Lab tests',
  'جدولة': 'Scheduling',
  'مرضى': 'Patients',
  'وصفات': 'Prescriptions',
  'أهلاً بعودتك': 'Welcome back',
  'تسجيل دخول المريض': 'Patient sign in',
  'تسجيل دخول الطبيب': 'Doctor sign in',
  'ادخل إلى مواعيدك وملفك الطبي بأمان.':
      'Securely access your appointments and medical record.',
  'ادخل إلى مواعيدك وملفات مرضاك بأمان.':
      'Securely access your appointments and patient records.',
  'بيانات الدخول': 'Sign-in details',
  'رقم الهاتف': 'Phone number',
  '10 أرقام': '10 digits',
  'كلمة المرور': 'Password',
  'أدخل كلمة المرور': 'Enter your password',
  'تذكرني': 'Remember me',
  'تسجيل الدخول': 'Sign in',
  'ليس لديك حساب؟': "Don't have an account?",
  'أنشئ حساب جديد': 'Create an account',
  'أدخل رقم الهاتف': 'Enter your phone number',
  'رقم الهاتف يجب أن يكون 10 أرقام': 'The phone number must contain 10 digits',
  'كلمة المرور يجب أن تكون 8 أحرف على الأقل':
      'Password must be at least 8 characters',
  'كلمة المرور يجب أن تكون 6 أحرف على الأقل':
      'Password must be at least 6 characters',
  'هذا الحساب مسجل كطبيب، يرجى تسجيل الدخول كطبيب':
      'This account belongs to a doctor. Please use doctor sign in.',
  'هذا الحساب مسجل كمريض، يرجى تسجيل الدخول من صفحة المريض':
      'This account belongs to a patient. Please use patient sign in.',
  'إنشاء حساب جديد': 'Create a new account',
  'المعلومات الشخصية': 'Personal information',
  'ضع صورة شخصية': 'Add a profile photo',
  'أنشئ حسابك للوصول إلى خدمات نبض الصحية.':
      'Create your account to access Nabd health services.',
  'الاسم الأول': 'First name',
  'الاسم الأخير': 'Last name',
  'البريد الإلكتروني': 'Email address',
  'تأكيد كلمة المرور': 'Confirm password',
  'كلمة السر': 'Password',
  'أدخل كلمة السر': 'Enter your password',
  'تأكيد كلمة السر': 'Confirm password',
  'أعد إدخال كلمة السر': 'Re-enter your password',
  'إنشاء الحساب': 'Create account',
  'لديك حساب بالفعل؟': 'Already have an account?',
  'سجّل الدخول': 'Sign in',
  '{label} مطلوب': '{label} is required',
  '{label} يجب ألا يتجاوز 20 محرفاً': '{label} must not exceed 20 characters',
  'البريد الإلكتروني مطلوب': 'Email address is required',
  'أدخل بريد إلكتروني صحيح': 'Enter a valid email address',
  'رقم الهاتف مطلوب': 'Phone number is required',
  'كلمة المرور مطلوبة': 'Password is required',
  'تأكيد كلمة المرور مطلوب': 'Password confirmation is required',
  'كلمتا المرور غير متطابقتين': 'Passwords do not match',
  'رمز التحقق': 'Verification code',
  'أدخل الرمز المرسل إلى بريدك الإلكتروني':
      'Enter the code sent to your email address',
  'أدخل رمز التحقق المرسل إليك.': 'Enter the verification code sent to you.',
  'أدخل الرمز المرسل إلى {email}.': 'Enter the code sent to {email}.',
  'تأكيد الرمز': 'Verify code',
  'لم يصلك الرمز؟': "Didn't receive the code?",
  'ألم تتلقى الرمز؟': "Didn't receive the code?",
  'إعادة الإرسال': 'Resend',
  'أرسل الرمز': 'Send code',
  'أدخل رمز التحقق المؤلف من 6 أرقام': 'Enter the 6-digit verification code',
  'تم تأكيد بريدك، سجّل دخولك للمتابعة':
      'Your email has been verified. Sign in to continue.',
  'تم إرسال الرمز مجدداً': 'The code has been sent again',
  'الملف الطبي': 'Medical record',
  'معلوماتك الصحية': 'Your health information',
  'أكمل معلوماتك الصحية حتى يتم تجهيز ملفك الطبي بدقة.':
      'Complete your health information so we can prepare your medical record accurately.',
  'المعلومات الأساسية': 'Basic information',
  'تاريخ الميلاد': 'Date of birth',
  'اختر تاريخ الميلاد': 'Select date of birth',
  'الجنس': 'Gender',
  'اختر الجنس': 'Select gender',
  'ذكر': 'Male',
  'أنثى': 'Female',
  'العنوان': 'Address',
  'مثال: دمشق، سوريا': 'Example: Damascus, Syria',
  'زمرة الدم': 'Blood type',
  'اختر زمرة الدم': 'Select blood type',
  'الحالة الصحية': 'Health status',
  'هل لديك مرض مزمن؟': 'Do you have a chronic condition?',
  'مثل السكري، الضغط أو أمراض القلب.':
      'Such as diabetes, hypertension, or heart disease.',
  'مثل السكري، الضغط، أمراض القلب أو الربو.':
      'Such as diabetes, hypertension, heart disease, or asthma.',
  'وصف المرض المزمن': 'Chronic condition details',
  'اكتب وصف المرض المزمن': 'Describe the chronic condition',
  'هل لديك حساسية؟': 'Do you have any allergies?',
  'مثل حساسية الأدوية، الطعام أو المواد الطبية.':
      'Such as allergies to medicine, food, or medical materials.',
  'وصف الحساسية': 'Allergy details',
  'اكتب نوع الحساسية': 'Describe the allergy',
  'نعم': 'Yes',
  'لا': 'No',
  'متابعة': 'Continue',
  'حدد الجنس': 'Select your gender',
  'هذا الحقل مطلوب': 'This field is required',
  'الجنس مطلوب': 'Gender is required',
  'زمرة الدم مطلوبة': 'Blood type is required',
  'اكتمل {count} من 4': '{count} of 4 completed',
  'الإعدادات': 'Settings',
  'المظهر': 'Appearance',
  'الوضع الداكن': 'Dark mode',
  'المظهر الداكن مفعّل': 'Dark appearance is enabled',
  'المظهر الفاتح مفعّل': 'Light appearance is enabled',
  'اللغة': 'Language',
  'لغة التطبيق': 'App language',
  'العربية': 'Arabic',
  'الإنجليزية': 'English',
  'تبديل إلى الإنجليزية': 'Switch to English',
  'التبديل إلى العربية': 'Switch to Arabic',
  'الرئيسية': 'Home',
  'مواعيدي': 'My appointments',
  'حسابي': 'Profile',
  'أهلاً، {name}': 'Hello, {name}',
  'نتمنى لك يوماً صحياً 🤗': 'Wishing you a healthy day 🤗',
  'ابحث عن طبيب بالاسم...': 'Search for a doctor by name...',
  'التخصصات الطبية': 'Medical specialties',
  'أطباء مقترحون': 'Suggested doctors',
  'نتائج البحث': 'Search results',
  'لا يوجد طبيب بهذا الاسم.': 'No doctor was found with this name.',
  'لا يوجد أطباء متاحون حالياً.': 'No doctors are currently available.',
  'سنوات خبرة': 'years of experience',
  'إعادة المحاولة': 'Try again',
  'لا يوجد طبيب بهذا الاسم ضمن الاختصاص.':
      'No doctor with this name was found in this specialty.',
  'لا يوجد أطباء ضمن هذا الاختصاص حالياً.':
      'No doctors are currently available in this specialty.',
  'غير محدد': 'Not specified',
  'لا توجد بيانات': 'No data available',
  'ملف المريض الطبي': 'Patient medical record',
  'نظرة صحية عامة': 'Health overview',
  'آخر نبض مسجل': 'Latest recorded heart rate',
  'نبضة/دقيقة': 'bpm',
  'الحساسية': 'Allergies',
  'الأمراض المزمنة': 'Chronic conditions',
  'جاري تحميل الموعد...': 'Loading appointment...',
  'تعذر تحميل الموعد': 'Could not load the appointment',
  'لا يوجد موعد قادم': 'No upcoming appointment',
  'موعدي القادم': 'My next appointment',
  'تذكير دواء': 'Medicine reminder',
  'أضف تذكيراً': 'Add a reminder',
  '{count} تذكير نشط': '{count} active reminders',
  'إضافة': 'Add',
  'إدارة': 'Manage',
  'المعلومات الطبية': 'Medical information',
  'سجل الزيارات الطبية': 'Medical visit history',
  'تحديث الملف الطبي': 'Refresh medical record',
  'محفظتي': 'My wallet',
  'تسجيل الخروج': 'Sign out',
  'هل تريد الخروج؟': 'Do you want to sign out?',
  'ستحتاج لتسجيل الدخول مجدداً.': 'You will need to sign in again.',
  'إلغاء': 'Cancel',
  'خروج': 'Sign out',
  'المريض': 'Patient',
  'بيانات الحساب الشخصية': 'Personal account details',
  'البيانات الشخصية': 'Personal details',
  'معلومات التواصل': 'Contact information',
  'حالة الحساب': 'Account status',
  'حالة البريد الإلكتروني': 'Email status',
  'تم التحقق': 'Verified',
  'لم يتم التحقق بعد': 'Not verified yet',
  'جاري تحميل السجل الطبي...': 'Loading medical record...',
  'تعذر تحميل السجل الطبي.': 'Could not load the medical record.',
  'لا توجد زيارات طبية مسجلة حتى الآن.':
      'No medical visits have been recorded yet.',
  'تعذر تحديث الملف الطبي.': 'Could not refresh the medical record.',
  'نبض القلب': 'Heart rate',
  'غير مسجل': 'Not recorded',
  'الأمراض والحالات السابقة': 'Previous diseases and conditions',
  'ملاحظات الطبيب': "Doctor's notes",
  'إحالة المختبر والتحاليل المطلوبة': 'Lab referral and requested tests',
  'تمت الإحالة إلى المختبر': 'Referred to the laboratory',
  'إحالة الصيدلية': 'Pharmacy referral',
  'تمت الإحالة إلى الصيدلي': 'Referred to the pharmacist',
  'الوصفة الطبية': 'Prescription',
  'التعليمات': 'Instructions',
  'ملاحظات': 'Notes',
  'لا توجد أدوية مسجلة ضمن هذه الوصفة.':
      'No medicines are recorded in this prescription.',
  'الجرعة': 'Dosage',
  'التكرار': 'Frequency',
  'المدة': 'Duration',
  'الطبيب': 'Doctor',
  'يناير': 'January',
  'فبراير': 'February',
  'مارس': 'March',
  'أبريل': 'April',
  'مايو': 'May',
  'يونيو': 'June',
  'يوليو': 'July',
  'أغسطس': 'August',
  'سبتمبر': 'September',
  'أكتوبر': 'October',
  'نوفمبر': 'November',
  'ديسمبر': 'December',
  'لا توجد أيام متاحة لإعادة الجدولة حالياً.':
      'No days are currently available for rescheduling.',
  'اختر تاريخ الموعد الجديد': 'Choose the new appointment date',
  'لم يعد هناك وقت متاح في هذا اليوم.':
      'There are no available times left on this day.',
  'اختر الوقت الجديد': 'Choose the new time',
  'تم تحديث موعدك بنجاح.': 'Your appointment was updated successfully.',
  'تم تحديث موعدك بنجاح': 'Your appointment was updated successfully',
  'تعذر تعديل الموعد، حاول مرة أخرى.':
      'Could not update the appointment. Please try again.',
  'اختر وقت الموعد الجديد': 'Choose the new appointment time',
  'تأكيد': 'Confirm',
  'قيّم تجربتك': 'Rate your experience',
  'كيف كانت تجربتك مع {name}؟': 'How was your experience with {name}?',
  'إرسال التقييم': 'Submit rating',
  'شكراً لتقييمك!': 'Thank you for your rating!',
  'تعذر إرسال التقييم، حاول مرة أخرى':
      'Could not submit the rating. Please try again.',
  'قيد الانتظار': 'Pending',
  'المنتهية': 'Completed',
  'الملغاة': 'Cancelled',
  'لا توجد مواعيد': 'No appointments',
  'تذكيرات الأدوية': 'Medicine reminders',
  'تذكير جديد': 'New reminder',
  'حذف التذكير؟': 'Delete reminder?',
  'لن يصلك تنبيه {name} بعد الحذف.':
      'You will no longer receive reminders for {name}.',
  'تراجع': 'Keep',
  'حذف': 'Delete',
  'يومياً': 'Daily',
  'خيارات': 'Options',
  'تعديل': 'Edit',
  'إضافة تذكير دواء': 'Add medicine reminder',
  'تعديل التذكير': 'Edit reminder',
  'اسم الدواء': 'Medicine name',
  'أدخل اسم الدواء': 'Enter the medicine name',
  'الجرعة (اختياري)': 'Dosage (optional)',
  'مثال: حبة واحدة بعد الطعام': 'Example: one tablet after food',
  'وقت التذكير': 'Reminder time',
  'سيتكرر التذكير يومياً في الوقت المحدد':
      'The reminder will repeat daily at the selected time',
  'حفظ التذكير': 'Save reminder',
  'حفظ التعديل': 'Save changes',
  'لا توجد تذكيرات أدوية': 'No medicine reminders',
  'أضف دواءً ووقت تناوله ليصلك تنبيه يومي على جهازك.':
      'Add a medicine and time to receive a daily reminder on your device.',
  'إضافة أول تذكير': 'Add first reminder',
  'الإشعارات': 'Notifications',
  'قراءة الكل': 'Mark all as read',
  'تعذر تحميل الإشعارات': 'Could not load notifications',
  'لا توجد إشعارات حتى الآن': 'No notifications yet',
  'ستظهر هنا تحديثات مواعيدك ووصفاتك ومدفوعاتك.':
      'Updates about your appointments, prescriptions, and payments will appear here.',
  'الآن': 'Now',
  'منذ {count} دقيقة': '{count} minutes ago',
  'منذ {count} ساعة': '{count} hours ago',
  'منذ {count} يوم': '{count} days ago',
  'شحن المحفظة': 'Top up wallet',
  'شحن المحفظة متاح حاليًا من خلال العيادة مباشرة. تواصل مع الاستقبال لإضافة رصيد لمحفظتك.':
      'Wallet top-ups are currently available directly through the clinic. Contact reception to add funds to your wallet.',
  'حسناً': 'OK',
  'سجل الحركات': 'Transaction history',
  'لا توجد حركات بعد': 'No transactions yet',
  'رصيد المحفظة': 'Wallet balance',
  'ل.س': 'SYP',
  'طبيب مختص': 'Specialist doctor',
  'يمتلك خبرة تمتد لأكثر من {count} سنوات في تقديم الرعاية الطبية ومتابعة الحالات بدقة.':
      'Has more than {count} years of experience providing medical care and following cases closely.',
  'يمتلك خبرة واسعة في تقديم الرعاية الطبية ومتابعة الحالات بدقة.':
      'Has extensive experience providing medical care and following cases closely.',
  '{doctor} مختص في {specialty}، حاصل على {certificate}. {experience} يعمل على تقديم استشارات طبية واضحة وخطة علاج مناسبة لكل مريض.':
      '{doctor} specializes in {specialty} and holds {certificate}. {experience} Provides clear medical consultations and a suitable treatment plan for every patient.',
  '{doctor} مختص في {specialty}. {experience} يعمل على تقديم استشارات طبية واضحة وخطة علاج مناسبة لكل مريض.':
      '{doctor} specializes in {specialty}. {experience} Provides clear medical consultations and a suitable treatment plan for every patient.',
  'تفاصيل الطبيب': 'Doctor details',
  'خبرة': 'Experience',
  'عام خبرة': 'Years of experience',
  'تقييم': 'Rating',
  'نبذة عن الطبيب': 'About the doctor',
  'حجز موعد الآن': 'Book an appointment',
  'سعر الاستشارة': 'Consultation fee',
  'استخدم نقاطك': 'Use your points',
  'اختر طريقة الحجز': 'Choose your booking option',
  'رصيدك {balance} نقطة — كل موعد تحجزه يمنحك 20 نقطة بعد اكتماله':
      'Your balance is {balance} points — each booked appointment earns 20 points after completion',
  'حجز عادي بالسعر الكامل': 'Standard booking at full price',
  'احتفظ بنقاطك لاستخدامها لاحقاً': 'Keep your points for later',
  'استخدام 40 نقطة': 'Use 40 points',
  'خصم 30% على هذا الحجز': '30% off this booking',
  'إعدادات الخصم على الخادم لا تطابق 40 نقطة مقابل خصم 30%':
      'The server discount settings do not match 40 points for 30% off',
  'كل موعد تحجزه يمنحك 20 نقطة بعد اكتماله':
      'Each booked appointment earns 20 points after completion',
  'رصيدك: {balance} نقطة (كل {unit} نقطة = {discount}% خصم، بحد أقصى {max}%)':
      'Balance: {balance} points ({unit} points = {discount}% off, up to {max}%)',
  'جاري التحقق من الخصم...': 'Checking discount...',
  'خصم': 'Discount',
  'متاح': 'Available',
  'اختر التاريخ': 'Choose a date',
  'المسائية': 'Evening',
  'الصباحية': 'Morning',
  'الفترات المتاحة': 'Available times',
  'لا توجد فترات متاحة لهذا اليوم': 'No times are available for this day',
  'فات الوقت': 'Time passed',
  'صباحاً': 'Morning',
  'مساءً': 'Evening',
  'ملاحظة طبية': 'Medical note',
  'يرجى إحضار التقارير الطبية السابقة إذا كانت متوفرة.':
      'Please bring any previous medical reports if available.',
  'التاريخ المختار': 'Selected date',
  'قيمة الكشف': 'Consultation fee',
  'ر.س': 'SAR',
  'رصيد محفظتك: {balance} {currency}': 'Wallet balance: {balance} {currency}',
  'الرصيد غير كافٍ لإتمام الحجز': 'Insufficient balance to complete booking',
  'جاري الحجز...': 'Booking...',
  'تحقق من خصم النقاط': 'Check points discount',
  'اختر وقتاً لم يفت بعد': 'Choose a time that has not passed',
  'رصيد المحفظة غير كافٍ': 'Insufficient wallet balance',
  'تأكيد الحجز': 'Confirm booking',
  'لم يتم اختيار وقت': 'No time selected',
  'تعذر إتمام الحجز، حاول مرة أخرى':
      'Could not complete the booking. Please try again.',
  'تم إرسال طلب الحجز': 'Booking request sent',
  'طلبك مع {doctor}\n{date} الساعة {time} {period}\nبانتظار موافقة السكرتاريا':
      'Your request with {doctor}\n{date} at {time} {period}\nWaiting for clinic approval',
  'سيتم استخدام {points} نقطة بعد الموافقة (خصم {amount} {currency})':
      '{points} points will be used after approval ({amount} {currency} discount)',
  'الاثنين': 'Monday',
  'الثلاثاء': 'Tuesday',
  'الأربعاء': 'Wednesday',
  'الخميس': 'Thursday',
  'الجمعة': 'Friday',
  'السبت': 'Saturday',
  'الأحد': 'Sunday',
  'ص': 'AM',
  'م': 'PM',
  'تعذر جلب فترات دوام الطبيب': 'Could not load the doctor schedule',
  'تعذر جلب الأوقات المتاحة لهذا اليوم':
      'Could not load the available times for this day',
  'لديك موعد قادم في نفس الاختصاص. يمكنك الحجز بعد انتهاء الموعد الحالي أو إلغائه.':
      'You already have an upcoming appointment in this specialty. You can book after it ends or is cancelled.',
  'نقاطي': 'My points',
  'رصيد نقاطك': 'Your points balance',
  'التفاصيل': 'Details',
  'رصيدك الحالي': 'Current balance',
  'نقطة': 'points',
  'خصم {percent}% جاهز': '{percent}% discount available',
  'نحو الخصم القادم': 'Toward your next discount',
  'استخدم نقاطك عند حجز موعد جديد':
      'Use your points when booking a new appointment',
  'باقي {left} نقطة للوصول إلى {target} نقطة':
      '{left} points left to reach {target} points',
  'كل {unit} نقطة تمنحك خصماً {discount}% — حتى {max}%':
      'Every {unit} points gives you {discount}% off — up to {max}%',
  'لديك خصم جاهز للاستخدام في حجزك القادم':
      'You have a discount ready for your next booking',
  'باقي {left} نقطة لتحصل على خصم {discount}%':
      '{left} points left to get a {discount}% discount',
  'أهمية الترطيب اليومي': 'The importance of daily hydration',
  'اشرب 8 أكواب يومياً لتحافظ على نشاطك.':
      'Drink 8 glasses a day to stay active.',
  'فحص العين الدوري': 'Regular eye exams',
  'زيارة قصيرة قد تكشف مشاكل مبكرة.':
      'A short visit can detect problems early.',
  'العناية بصحة القلب': 'Taking care of your heart',
  'نمط حياة هادئ ومشي يومي يصنع فرقاً.':
      'A balanced lifestyle and a daily walk make a difference.',
  'موعد': 'Appointment',
  'الرصيد': 'Balance',
  'نقاط إتمام موعد': 'Appointment completion points',
  'استخدام نقاط في حجز': 'Points used for booking',
  'استرجاع نقاط موعد': 'Appointment points refund',
  'تعديل رصيد النقاط': 'Points balance adjustment',
  'حركة نقاط': 'Points transaction',
  'لا توجد حركات نقاط حتى الآن': 'No points transactions yet',
  'بانتظار موافقة السكرتاريا': 'Waiting for clinic approval',
  'للإلغاء تواصل مع العيادة': 'Contact the clinic to cancel',
  'إعادة جدولة': 'Reschedule',
  'قيّم الطبيب': 'Rate doctor',
  'تقييمك: {rating}/10': 'Your rating: {rating}/10',
  'مرفوض': 'Rejected',
  'ملغى': 'Cancelled',
  'لم يحضر': 'No-show',
  'بانتظار تأكيد العيادة': 'Waiting for clinic confirmation',
  'مكتمل': 'Completed',
  'سبب الرفض: {reason}': 'Rejection reason: {reason}',
  'يجب السماح بالإشعارات لتفعيل تذكير الدواء.':
      'Allow notifications to enable medicine reminders.',
  'تعذر حفظ التذكير. حاول مجدداً.':
      'Could not save the reminder. Please try again.',

  // Doctor application
  'إجراءات سريعة': 'Quick actions',
  'إتمام الزيارة': 'Complete visit',
  'التحاليل': 'Lab tests',
  'الوصفات': 'Prescriptions',
  'إجمالي المواعيد': 'Total appointments',
  'إحالات التحاليل': 'Lab referrals',
  'إحالة إلى الصيدلية': 'Refer to pharmacy',
  'إحالة إلى المختبر': 'Refer to laboratory',
  'إضافة الدواء': 'Add medicine',
  'إضافة دواء': 'Add medicine',
  'إضافة دواء إلى الوصفة': 'Add medicine to prescription',
  'إلغاء التعديل': 'Cancel editing',
  'إليك نظرة سريعة على يومك الطبي':
      'Here is a quick overview of your clinical day',
  'اسم الدواء *': 'Medicine name *',
  'أدخل التشخيص الرئيسي للحالة... *': 'Enter the primary diagnosis... *',
  'أدخل بيانات السجل الطبي بدقة': 'Enter the medical record details accurately',
  'اكتب ملاحظات التحويل أو تعليمات المخبر...':
      'Enter referral notes or laboratory instructions...',
  'اكتب ملاحظاتك السريرية هنا...': 'Enter your clinical notes here...',
  'الأدوية': 'Medicines',
  'الأدوية الموصوفة': 'Prescribed medicines',
  'البرنامج الأسبوعي': 'Weekly schedule',
  'البريد': 'Email',
  'البيانات الحيوية': 'Vital signs',
  'التحويلات': 'Referrals',
  'التشخيص': 'Diagnosis',
  'التشخيص *': 'Diagnosis *',
  'التنبيهات': 'Alerts',
  'التوفر خلال الأسبوعين القادمين': 'Availability during the next two weeks',
  'التكرار (مثال: كل 12 ساعة) *': 'Frequency (example: every 12 hours) *',
  'الجرعة *': 'Dosage *',
  'الحساسيات': 'Allergies',
  'الحساسيات المسجلة': 'Recorded allergies',
  'الحساسية / الأمراض المزمنة': 'Allergies / chronic conditions',
  'الزيارة التالية': 'Next visit',
  'السجل': 'Records',
  'السجل الطبي': 'Medical record',
  'السجلات': 'Records',
  'الفحوصات المطلوبة *': 'Required tests *',
  'القادمة': 'Upcoming',
  'المدة (مثال: 7 أيام) *': 'Duration (example: 7 days) *',
  'المكتملة': 'Completed',
  'الملاحظات': 'Notes',
  'المواعيد القادمة': 'Upcoming appointments',
  'الموعد': 'Appointment',
  'الموعد التالي': 'Next appointment',
  'الهاتف': 'Phone',
  'الوصفات الطبية': 'Prescriptions',
  'الوصفة': 'Prescription',
  'اليوم': 'Today',
  'انتظار': 'Waiting',
  'بانتظار الصرف': 'Awaiting dispensing',
  'بانتظار الوصول': 'Awaiting arrival',
  'بدء المعاينة': 'Start examination',
  'تحتاج إلى انتباه': 'Needs attention',
  'تحويل إلى الصيدلية': 'Refer to pharmacy',
  'تحويل إلى المختبر': 'Refer to laboratory',
  'تعديل الدوام والإجازات يتم من لوحة الإدارة.':
      'Working hours and leave are managed from the admin dashboard.',
  'تعديل الوصفة': 'Edit prescription',
  'تعذر تحميل بيانات الطبيب.': 'Could not load doctor data.',
  'تعذر تحميل تفاصيل الوصفة.': 'Could not load prescription details.',
  'تعذر تحميل جدول الدوام. حاول مجدداً.':
      'Could not load the schedule. Please try again.',
  'تعذر تعديل السجل.': 'Could not update the record.',
  'تعذر تعديل الوصفة.': 'Could not update the prescription.',
  'تعذر جلب المواعيد من الخادم': 'Could not load appointments from the server',
  'تعذر حذف السجل.': 'Could not delete the record.',
  'تعذر حذف الوصفة.': 'Could not delete the prescription.',
  'تعليمات الوصفة العامة': 'General prescription instructions',
  'تفاصيل السجل الطبي': 'Medical record details',
  'تفاصيل المريض': 'Patient details',
  'تفاصيل الوصفة': 'Prescription details',
  'تم التسعير': 'Priced',
  'تم الصرف': 'Dispensed',
  'تم تعديل الوصفة بنجاح.': 'Prescription updated successfully.',
  'تم حفظ التعديلات.': 'Changes saved.',
  'تنبيهات جديدة': 'New alerts',
  'جارٍ الحفظ...': 'Saving...',
  'جدول الدوام': 'Work schedule',
  'جدول اليوم وجميع المراجعين': "Today's schedule and all patients",
  'جدول مواعيد اليوم': "Today's appointments",
  'حالة طلب المختبر': 'Laboratory request status',
  'حذف السجل الطبي؟': 'Delete medical record?',
  'حذف الوصفة': 'Delete prescription',
  'حذف الوصفة؟': 'Delete prescription?',
  'حفظ التعديلات': 'Save changes',
  'حفظ كمسودة': 'Save as draft',
  'حفظ وإنهاء الزيارة': 'Save and complete visit',
  'حفظ وإنهاء المعاينة': 'Save and complete examination',
  'دواء': 'Medicine',
  'ساعات العمل والأيام المتاحة': 'Working hours and available days',
  'سيتم حذف السجل نهائياً ولا يمكن التراجع عن هذه العملية.':
      'The record will be permanently deleted and cannot be restored.',
  'سيتم حذف الوصفة وأدويتها نهائياً.':
      'The prescription and its medicines will be permanently deleted.',
  'ط': 'D',
  'عرض الرصيد وسجل الحركات': 'View balance and transaction history',
  'عرض الكل': 'View all',
  'عرض الملف الطبي': 'View medical record',
  'غير متاح': 'Unavailable',
  'غير متوفر': 'Unavailable',
  'فصيلة الدم': 'Blood type',
  'في العيادة': 'At the clinic',
  'قائمة المواعيد': 'Appointment list',
  'لا تنبيهات': 'No alerts',
  'لا توجد أدوية في الوصفة': 'No medicines in the prescription',
  'لا توجد إحالات مخبرية حالياً': 'No laboratory referrals currently',
  'لا توجد بيانات مرضى حالياً': 'No patient data currently',
  'لا توجد تنبيهات حالياً': 'No alerts currently',
  'لا توجد سجلات سابقة لهذا المريض': 'No previous records for this patient',
  'لا توجد سجلات طبية حالياً': 'No medical records currently',
  'لا توجد مواعيد ضمن هذا التصنيف': 'No appointments in this category',
  'لا توجد مواعيد قادمة': 'No upcoming appointments',
  'لا توجد مواعيد لعرضها': 'No appointments to display',
  'لا توجد وصفات طبية حالياً': 'No prescriptions currently',
  'لا مواعيد اليوم': 'No appointments today',
  'لا يوجد انتظار': 'No one is waiting',
  'لا يوجد موعد قادم حالياً': 'No upcoming appointment currently',
  'لم تتم إضافة أدوية إلى الوصفة.':
      'No medicines have been added to the prescription.',
  'لم يتم تحديد جدول دوام بعد': 'No work schedule has been set yet',
  'مؤكد': 'Confirmed',
  'مؤكدة': 'Confirmed',
  'محفظة الدكتور': "Doctor's wallet",
  'مدفوعة': 'Paid',
  'مرحباً د. ': 'Hello Dr. ',
  'مرضاي': 'My patients',
  'مرضى بانتظارك': 'Patients waiting',
  'ملاحظات التحويل / المخبر': 'Referral / laboratory notes',
  'ملاحظات الدواء': 'Medicine notes',
  'ملاحظات المختبر': 'Laboratory notes',
  'ملاحظات المعاينة': 'Examination notes',
  'ملاحظات الوصفة': 'Prescription notes',
  'ملغي': 'Cancelled',
  'مواعيد اليوم': "Today's appointments",
  'نبض': 'Nabd',
  'نبض القلب يجب أن يكون رقماً صحيحاً.': 'Heart rate must be a valid number.',
  'نوع الزيارة': 'Visit type',
  'يجب أن تحتوي الوصفة على دواء واحد على الأقل.':
      'The prescription must contain at least one medicine.',
  'يرجى إدخال التشخيص.': 'Please enter the diagnosis.',
  'تعذر إنهاء الزيارة. تحقق من البيانات وحاول مجددًا.':
      'Could not complete the visit. Check the information and try again.',
  'تعذر تحميل لوحة الطبيب. تحقق من الاتصال وحاول مجددًا.':
      'Could not load the doctor dashboard. Check your connection and try again.',
  'تعذر تعديل السجل الطبي. حاول مجدداً.':
      'Could not update the medical record. Please try again.',
  'تعذر تعديل الوصفة. حاول مجدداً.':
      'Could not update the prescription. Please try again.',
  'تعذر جلب المواعيد من الخادم.':
      'Could not load appointments from the server.',
  'تعذر حذف السجل الطبي. حاول مجدداً.':
      'Could not delete the medical record. Please try again.',
  'تعذر حذف الوصفة. حاول مجدداً.':
      'Could not delete the prescription. Please try again.',
  'تعذر حفظ المعاينة. حاول مجددًا.':
      'Could not save the examination. Please try again.',
  'تم إنشاء السجل لكن الاستجابة لم تتضمن medical_record_id لإنشاء الوصفة.':
      'The record was created, but the response did not include a medical record ID for the prescription.',
  'تم تعديل السجل الطبي بنجاح.': 'The medical record was updated successfully.',
  'تم حذف السجل الطبي.': 'The medical record was deleted.',
  'تم حذف الوصفة.': 'The prescription was deleted.',
  'تم حفظ السجل وإنهاء الزيارة بنجاح.':
      'The record was saved and the visit completed successfully.',
  'تم حفظ السجل والوصفة وإنهاء الزيارة بنجاح.':
      'The record and prescription were saved and the visit completed successfully.',
  'تم حفظ المعاينة والسجل الطبي بنجاح.':
      'The examination and medical record were saved successfully.',
  'تم حفظ مسودة الزيارة على الجهاز.':
      'The visit draft was saved on this device.',
  'عدد التنبيهات': 'Alert count',
  'استشارة طبية': 'Medical consultation',
  'تنبيه جديد': 'New alert',
  'حدث خطأ في جلب التخصصات': 'Could not load specialties',
  'حدث خطأ في جلب أطباء التخصص': 'Could not load doctors for this specialty',
  'حدث خطأ في جلب قائمة الأطباء': 'Could not load the doctor list',
  'تعذر تحميل رصيد النقاط': 'Could not load the points balance',
  'طب القلب': 'Cardiology',
  'طب الأسنان': 'Dentistry',
  'طب العيون': 'Ophthalmology',
  'الجلدية': 'Dermatology',
  'طب الجلدية': 'Dermatology',
  'العظام': 'Orthopedics',
  'طب العظام': 'Orthopedics',
  'طب الأطفال': 'Pediatrics',
  'الطب النفسي': 'Psychiatry',
  'الباطنة': 'Internal medicine',
  'الطب الباطني': 'Internal medicine',
};

String? _translateDynamicArabic(String source) {
  Match? match;

  match = RegExp(r'^(.+) دقيقة$').firstMatch(source);
  if (match != null) {
    return '${_translateEmbeddedDateTerms(match.group(1)!)} min';
  }

  match = RegExp(r'^(\d+) موعد$').firstMatch(source);
  if (match != null) return '${match.group(1)} appointments';

  match = RegExp(r'^(\d+) مريض$').firstMatch(source);
  if (match != null) return '${match.group(1)} patients';

  match = RegExp(r'^(\d+) سجل$').firstMatch(source);
  if (match != null) return '${match.group(1)} records';

  match = RegExp(r'^(\d+) أدوية$').firstMatch(source);
  if (match != null) return '${match.group(1)} medicines';

  match = RegExp(r'^(\d+) موعد متاح$').firstMatch(source);
  if (match != null) return '${match.group(1)} available appointments';

  match = RegExp(r'^د\. (.+)$').firstMatch(source);
  if (match != null) return 'Dr. ${match.group(1)}';

  match = RegExp(r'^معاينة (.+)$').firstMatch(source);
  if (match != null) return 'Examine ${match.group(1)}';

  match = RegExp(r'^الحالة: (.+)$').firstMatch(source);
  if (match != null) {
    final status = match.group(1)!;
    return 'Status: ${_englishTranslations[status] ?? status}';
  }

  match = RegExp(r'^تاريخ الإصدار: (.+)$').firstMatch(source);
  if (match != null) return 'Issue date: ${match.group(1)}';

  match = RegExp(r'^تاريخ السجل: (.+)$').firstMatch(source);
  if (match != null) return 'Record date: ${match.group(1)}';

  match = RegExp(r'^من (.+) إلى (.+)$').firstMatch(source);
  if (match != null) {
    return 'From ${_translateEmbeddedDateTerms(match.group(1)!)} '
        'to ${_translateEmbeddedDateTerms(match.group(2)!)}';
  }

  match = RegExp(r'^(.+) (ص|م)$').firstMatch(source);
  if (match != null) {
    return '${match.group(1)} ${match.group(2) == 'ص' ? 'AM' : 'PM'}';
  }

  for (final entry in _englishTranslations.entries) {
    if (source.startsWith('${entry.key}،')) {
      return source.replaceFirst(entry.key, entry.value);
    }
  }
  final dateText = _translateEmbeddedDateTerms(source);
  return dateText == source ? null : dateText;
}

String _translateEmbeddedDateTerms(String source) {
  var result = source;
  const terms = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  for (final term in terms) {
    result = result.replaceAll(term, _englishTranslations[term] ?? term);
  }
  result = result.replaceAllMapped(
    RegExp(r'(\d) ص\b'),
    (match) => '${match.group(1)} AM',
  );
  result = result.replaceAllMapped(
    RegExp(r'(\d) م\b'),
    (match) => '${match.group(1)} PM',
  );
  return result;
}
