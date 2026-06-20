# الميزات المنجزة في SmartPocket

توثيق للميزات والوظائف المنجزة حتى تاريخه في تطبيق **SmartPocket** — تطبيق تتبع مصاريف شخصي يعمل **محلياً بالكامل** (offline-first) دون اعتماد على خادم خارجي.

**التقنيات الأساسية:** Flutter، إدارة الحالة Riverpod، التوجيه GoRouter، قاعدة بيانات SQLite عبر `sqflite`، مع بوابة **FFI** لدعم تشغيل قاعدة البيانات على سطح المكتب عند الحاجة.

---

## قاعدة البيانات المحلية

- **اسم الملف:** `smartpocket.db`
- **الإصدار الحالي:** `8` (ترحيلات من v1 إلى v8 في `onUpgrade`)
- **المفاتيح الأجنبية:** مفعّلة (`PRAGMA foreign_keys = ON`)
- **المبالغ:** تُخزَّن كأعداد صحيحة بصيغة `*_minor` (أصغر وحدة نقدية)
- **العملة:** حقول `currency_code` على السجلات ذات الصلة (افتراضي `SYP` في المخطط)

**الجداول (أسماء الثوابت في الكود واسم الجدول الفعلي):**

- `tableCategories` → `categories`
- `tableExpenses` → `expenses`
- `tableBudgets` → `budgets`
- `tableSettings` → `settings`
- `tableIncomes` → `incomes`
- `tableDebts` → `debts`
- `tableDebtPayments` → `debt_payments`
- `tableRecurringEntries` → `recurring_entries`
- `tableSavingsGoals` → `savings_goals`
- `tableSavingsGoalContributions` → `savings_goal_contributions`

**ملفات مرجعية:**

- [db_constants.dart](smartpocket/lib/core/constants/db_constants.dart)
- [database_helper.dart](smartpocket/lib/core/database/database_helper.dart)

---

## خريطة المسارات (Routes)

- **`/onboarding`:** شاشة التهيئة الأولى (يُوجَّه إليها تلقائياً إن لم يُكمل المستخدم الإعداد)
- **الغلاف `StatefulShellRoute` (تبويبات رئيسية):**
  - **`/home`:** الرئيسية
  - **`/categories`:** الأقسام (مع مسارات فرعية للمصاريف، الدخل، الديون، المتكرر، أهداف التوفير)
  - **`/reports`:** التقارير
  - **`/settings`:** الإعدادات
- **أمثلة مسارات فرعية تحت فرع الأقسام:** `/categories/browse`, `/categories/:id`, `/expense/add`, `/expense/edit/:id`, `/incomes`, `/income/add`, `/income/edit/:id`, `/debts`, `/debt/add`, `/debt/:id`, `/debt/edit/:id`, `/recurring`, `/recurring/add`, `/recurring/edit/:id`, `/savings-goals`, `/savings-goal/add`, `/savings-goal/edit/:id`

**ملف مرجعي:**

- [app_router.dart](smartpocket/lib/core/router/app_router.dart)

---

## المعمارية والقاعدة المحلية

تطبيق يفتح قاعدة SQLite عند الإقلاع، يطبّق مخطط الإنشاء أو الترحيل، ويزرع فئاتاً افتراضية عند أول تشغيل. يوجد تهيئة **SQLite FFI** للمنصات التي تحتاجها.

- ترحيلات متعددة (إصدارات قاعدة البيانات) تشمل إضافة جداول وحقول للديون، الدفعات، الميزانيات، أهداف التوفير، المساهمات، وفترات التنبيه.
- **ملاحظة:** ترحيل v6→v7 أعاد إنشاء جدول أهداف التوفير؛ التعليق في الكود يشير إلى قرار منتج بإسقاط صفوف قديمة.

**ملفات رئيسية:**

- [main.dart](smartpocket/lib/main.dart)
- [database_helper.dart](smartpocket/lib/core/database/database_helper.dart)
- [sqlite_ffi_gate.dart](smartpocket/lib/core/database/sqlite_ffi_gate.dart)
- [sqlite_ffi_io.dart](smartpocket/lib/core/database/sqlite_ffi_io.dart)
- [sqlite_ffi_stub.dart](smartpocket/lib/core/database/sqlite_ffi_stub.dart)
- [default_categories.dart](smartpocket/lib/core/constants/default_categories.dart)
- [database_provider.dart](smartpocket/lib/presentation/providers/database_provider.dart)

---

## التهيئة الأولية (Onboarding)

جمع بيانات أولية مثل الرصيد الافتتاحي، الدخل الشهري الافتراضي، العملة الأساسية، وإكمال العلم `onboarding_completed` في الإعدادات؛ يمنع التوجيه المتكرر بعد الإكمال.

**ملفات رئيسية:**

- [onboarding_screen.dart](smartpocket/lib/presentation/screens/onboarding_screen.dart)
- [app_router.dart](smartpocket/lib/core/router/app_router.dart) (منطق `redirect`)
- [settings_entity.dart](smartpocket/lib/domain/entities/settings_entity.dart)
- [settings_local_datasource.dart](smartpocket/lib/data/datasources/local/settings_local_datasource.dart)

---

## الغلاف الرئيسي والتنقل

واجهة بأربعة أقسام رئيسية (رئيسية، أقسام، تقارير، إعدادات) عبر `StatefulShellRoute`، مع تهيئة الإشعارات المحلية عند الحاجة وربطها بخدمات التذكير والعناصر الدورية.

**ملفات رئيسية:**

- [main_shell_screen.dart](smartpocket/lib/presentation/screens/main_shell_screen.dart)

---

## لوحة الرئيسية (Dashboard)

عرض ملخص مالي للشهر: بطاقات للرصيد والدخل والمصاريف وصافي التوفير، أكثر فئة صرفاً، رؤى ذكية، آخر المصاريف، معاينة أهداف التوفير، وتنبيه عند تجاوز ميزانية فئة حسب فترة التنبيه المضبوطة.

**ملفات رئيسية:**

- [home_screen.dart](smartpocket/lib/presentation/screens/home_screen.dart)
- [dashboard_provider.dart](smartpocket/lib/presentation/providers/dashboard_provider.dart)
- [dashboard_repository.dart](smartpocket/lib/domain/repositories/dashboard_repository.dart)
- [dashboard_repository_impl.dart](smartpocket/lib/data/repositories/dashboard_repository_impl.dart)
- [dashboard_snapshot.dart](smartpocket/lib/domain/entities/dashboard_snapshot.dart)
- [budget_overrun_provider.dart](smartpocket/lib/presentation/providers/budget_overrun_provider.dart)
- [finance_top_tabs.dart](smartpocket/lib/presentation/widgets/finance_top_tabs.dart)
- [month_nav_bar.dart](smartpocket/lib/presentation/widgets/month_nav_bar.dart)

---

## المصاريف (Expenses)

إضافة وتعديل مصاريف مرتبطة بفئة، مع مبلغ، تاريخ، ملاحظة، وعملة. عرض مصاريف الشهر مع إمكانيات تصفية وبحث ضمن تدفق الأقسام وتفاصيل الفئة.

**ملفات رئيسية:**

- [add_edit_expense_screen.dart](smartpocket/lib/presentation/screens/add_edit_expense_screen.dart)
- [categories_screen.dart](smartpocket/lib/presentation/screens/categories_screen.dart)
- [category_details_screen.dart](smartpocket/lib/presentation/screens/category_details_screen.dart)
- [expense_entity.dart](smartpocket/lib/domain/entities/expense_entity.dart)
- [expense_repository.dart](smartpocket/lib/domain/repositories/expense_repository.dart)
- [expense_repository_impl.dart](smartpocket/lib/data/repositories/expense_repository_impl.dart)
- [expense_local_datasource.dart](smartpocket/lib/data/datasources/local/expense_local_datasource.dart)
- [expense_month_provider.dart](smartpocket/lib/presentation/providers/expense_month_provider.dart)
- [spent_by_category_provider.dart](smartpocket/lib/presentation/providers/spent_by_category_provider.dart)

---

## الدخل (Incomes)

قائمة دخل مع إضافة وتعديل: مبلغ، تاريخ، مصدر نصي، وعملة؛ مصادر مقترحة من ثوابت افتراضية لتسريع الإدخال.

**ملفات رئيسية:**

- [incomes_screen.dart](smartpocket/lib/presentation/screens/incomes_screen.dart)
- [add_edit_income_screen.dart](smartpocket/lib/presentation/screens/add_edit_income_screen.dart)
- [default_income_sources.dart](smartpocket/lib/core/constants/default_income_sources.dart)
- [income_entity.dart](smartpocket/lib/domain/entities/income_entity.dart)
- [income_repository.dart](smartpocket/lib/domain/repositories/income_repository.dart)
- [income_repository_impl.dart](smartpocket/lib/data/repositories/income_repository_impl.dart)
- [income_local_datasource.dart](smartpocket/lib/data/datasources/local/income_local_datasource.dart)
- [income_month_provider.dart](smartpocket/lib/presentation/providers/income_month_provider.dart)

---

## الفئات (Categories)

زرع فئات افتراضية عند إنشاء القاعدة (أسماء وأيقونات وألوان). دليل فئات وتفاصيل فئة تعرض نشاط الشهر وربط الميزانية؛ الطبقة الخلفية تدعم عمليات مستودع الفئات.

**ملفات رئيسية:**

- [default_categories.dart](smartpocket/lib/core/constants/default_categories.dart)
- [category_directory_screen.dart](smartpocket/lib/presentation/screens/category_directory_screen.dart)
- [category_details_screen.dart](smartpocket/lib/presentation/screens/category_details_screen.dart)
- [category_entity.dart](smartpocket/lib/domain/entities/category_entity.dart)
- [category_repository.dart](smartpocket/lib/domain/repositories/category_repository.dart)
- [category_repository_impl.dart](smartpocket/lib/data/repositories/category_repository_impl.dart)
- [category_local_datasource.dart](smartpocket/lib/data/datasources/local/category_local_datasource.dart)
- [categories_list_provider.dart](smartpocket/lib/presentation/providers/categories_list_provider.dart)
- [category_icon.dart](smartpocket/lib/presentation/utils/category_icon.dart)

---

## الميزانيات لكل فئة

حد إنفاق شهري لكل `(فئة، سنة، شهر)` مع **فترة تنبيه** (مثل شهر / أسبوع / يوم) لكل ميزانية؛ حساب الإنفاق ضمن الفترة عبر دوال رياضية مخصصة؛ عرض تنبيه تجاوز في الرئيسية عند الحاجة.

**ملفات رئيسية:**

- [budget_entity.dart](smartpocket/lib/domain/entities/budget_entity.dart)
- [budget_alert_period.dart](smartpocket/lib/domain/value_objects/budget_alert_period.dart)
- [budget_repository.dart](smartpocket/lib/domain/repositories/budget_repository.dart)
- [budget_repository_impl.dart](smartpocket/lib/data/repositories/budget_repository_impl.dart)
- [budget_local_datasource.dart](smartpocket/lib/data/datasources/local/budget_local_datasource.dart)
- [category_budget_provider.dart](smartpocket/lib/presentation/providers/category_budget_provider.dart)
- [budget_month_provider.dart](smartpocket/lib/presentation/providers/budget_month_provider.dart)
- [budget_chart_provider.dart](smartpocket/lib/presentation/providers/budget_chart_provider.dart)
- [budget_period_math.dart](smartpocket/lib/presentation/utils/budget_period_math.dart)

---

## الديون والدفعات

ديون بنوع (مثلاً عليّ / لي) مع حالات، مبالغ مدفوعة ومتبقية، تاريخ استحقاق، ربط اختياري بجهة اتصال (`contact_id`)، ملاحظة، وعملة. سجل دفعات منفصل مرتبط بالدين.

**ملفات رئيسية:**

- [debts_screen.dart](smartpocket/lib/presentation/screens/debts_screen.dart)
- [debt_details_screen.dart](smartpocket/lib/presentation/screens/debt_details_screen.dart)
- [add_edit_debt_screen.dart](smartpocket/lib/presentation/screens/add_edit_debt_screen.dart)
- [debt_entity.dart](smartpocket/lib/domain/entities/debt_entity.dart)
- [debt_payment_entity.dart](smartpocket/lib/domain/entities/debt_payment_entity.dart)
- [debt_repository.dart](smartpocket/lib/domain/repositories/debt_repository.dart)
- [debt_repository_impl.dart](smartpocket/lib/data/repositories/debt_repository_impl.dart)
- [debt_local_datasource.dart](smartpocket/lib/data/datasources/local/debt_local_datasource.dart)
- [debts_provider.dart](smartpocket/lib/presentation/providers/debts_provider.dart)
- [debt_payments_provider.dart](smartpocket/lib/presentation/providers/debt_payments_provider.dart)
- [debt_reminder_service.dart](smartpocket/lib/core/services/debt_reminder_service.dart)

---

## العناصر الدورية (Recurring)

تعريف عناصر تتكرر شهرياً حسب **يوم من الشهر** وأنواع مختلفة (دخل، مصروف، دين، إلخ) مع حمولة JSON؛ محرك يتحقق من اليوم الحالي ويعرض إشعاراً وحوار تأكيد لتوليد سجل فعلي وتحديث آخر شهر مؤكد.

**ملفات رئيسية:**

- [recurring_engine_service.dart](smartpocket/lib/core/services/recurring_engine_service.dart)
- [recurring_entries_screen.dart](smartpocket/lib/presentation/screens/recurring_entries_screen.dart)
- [add_edit_recurring_entry_screen.dart](smartpocket/lib/presentation/screens/add_edit_recurring_entry_screen.dart)
- [recurring_entry_entity.dart](smartpocket/lib/domain/entities/recurring_entry_entity.dart)
- [recurring_repository.dart](smartpocket/lib/domain/repositories/recurring_repository.dart)
- [recurring_repository_impl.dart](smartpocket/lib/data/repositories/recurring_repository_impl.dart)
- [recurring_local_datasource.dart](smartpocket/lib/data/datasources/local/recurring_local_datasource.dart)
- [recurring_provider.dart](smartpocket/lib/presentation/providers/recurring_provider.dart)

---

## أهداف التوفير والمساهمات

أهداف بعنوان، مبلغ مستهدف، مبلغ موفر، تواريخ بداية ونهاية، حالة، وعملة. مساهمات مرتبطة بالهدف مع مصدر وربط اختياري بمصروف. دوال مساعدة لتقدير الادخار الشهري المطلوب والمتبقي.

**ملفات رئيسية:**

- [savings_goals_screen.dart](smartpocket/lib/presentation/screens/savings_goals_screen.dart)
- [add_edit_savings_goal_screen.dart](smartpocket/lib/presentation/screens/add_edit_savings_goal_screen.dart)
- [savings_goal_entity.dart](smartpocket/lib/domain/entities/savings_goal_entity.dart)
- [saving_goal_contribution_entity.dart](smartpocket/lib/domain/entities/saving_goal_contribution_entity.dart)
- [savings_goal_repository.dart](smartpocket/lib/domain/repositories/savings_goal_repository.dart)
- [savings_goal_repository_impl.dart](smartpocket/lib/data/repositories/savings_goal_repository_impl.dart)
- [savings_goal_local_datasource.dart](smartpocket/lib/data/datasources/local/savings_goal_local_datasource.dart)
- [savings_goals_provider.dart](smartpocket/lib/presentation/providers/savings_goals_provider.dart)
- [savings_goal_math.dart](smartpocket/lib/presentation/utils/savings_goal_math.dart)

---

## التقارير

تبويبات **يومي / شهري / سنوي** مع إحصاءات ومقارنات (مثل مصروف اليوم مقارنة بفترة سابقة)، رسوم بيانية (أعمدة أيام، أشهر، خط اتجاه، دائرة فئات، بطاقة تدفق نقدي)، قسم رؤى، وحوار **تصدير** إلى **PDF** أو **Excel** مع اختيار النطاق والفترة.

**ملفات رئيسية:**

- [reports_screen.dart](smartpocket/lib/presentation/screens/reports/reports_screen.dart)
- [daily_report_tab.dart](smartpocket/lib/presentation/screens/reports/tabs/daily_report_tab.dart)
- [monthly_report_tab.dart](smartpocket/lib/presentation/screens/reports/tabs/monthly_report_tab.dart)
- [yearly_report_tab.dart](smartpocket/lib/presentation/screens/reports/tabs/yearly_report_tab.dart)
- [reports_providers.dart](smartpocket/lib/presentation/providers/reports/reports_providers.dart)
- [selected_day_provider.dart](smartpocket/lib/presentation/providers/reports/selected_day_provider.dart)
- [selected_year_provider.dart](smartpocket/lib/presentation/providers/reports/selected_year_provider.dart)
- [reports_repository.dart](smartpocket/lib/domain/repositories/reports_repository.dart)
- [reports_repository_impl.dart](smartpocket/lib/data/repositories/reports_repository_impl.dart)
- [report_export_service.dart](smartpocket/lib/data/services/report_export_service.dart)
- ويدجت التقارير: [export_report_dialog.dart](smartpocket/lib/presentation/widgets/reports/export_report_dialog.dart)، [category_pie_chart.dart](smartpocket/lib/presentation/widgets/reports/category_pie_chart.dart)، [days_bar_chart.dart](smartpocket/lib/presentation/widgets/reports/days_bar_chart.dart)، [months_bar_chart.dart](smartpocket/lib/presentation/widgets/reports/months_bar_chart.dart)، [trend_line_chart.dart](smartpocket/lib/presentation/widgets/reports/trend_line_chart.dart)، [cash_flow_card.dart](smartpocket/lib/presentation/widgets/reports/cash_flow_card.dart)، [comparison_chip.dart](smartpocket/lib/presentation/widgets/reports/comparison_chip.dart)، [insights_section.dart](smartpocket/lib/presentation/widgets/reports/insights_section.dart)، [report_stat_card.dart](smartpocket/lib/presentation/widgets/reports/report_stat_card.dart)، [year_nav_bar.dart](smartpocket/lib/presentation/widgets/reports/year_nav_bar.dart)

**كيانات تقارير (domain):** مجلد [lib/domain/entities/reports/](smartpocket/lib/domain/entities/reports/) (مثل `daily_report.dart`, `monthly_report.dart`, `yearly_report.dart`, `category_analysis.dart`, `comparison_result.dart`, `report_insight.dart`, `trend_point.dart`, `period_range.dart`)

---

## الإعدادات

تعديل الإعدادات المالية (رصيد افتتاحي، دخل شهري افتراضي، عملة أساسية)، تبديل المظهر (مع حفظ التفضيل)، وروابط سريعة لشاشات الدخل والديون والمتكرر وأهداف التوفير؛ يمكن الوصول لتصدير التقارير من سياق الإعدادات حسب التصميم الحالي.

**ملفات رئيسية:**

- [settings_screen.dart](smartpocket/lib/presentation/screens/settings_screen.dart)
- [settings_entity.dart](smartpocket/lib/domain/entities/settings_entity.dart)
- [settings_repository.dart](smartpocket/lib/domain/repositories/settings_repository.dart)
- [settings_repository_impl.dart](smartpocket/lib/data/repositories/settings_repository_impl.dart)
- [settings_local_datasource.dart](smartpocket/lib/data/datasources/local/settings_local_datasource.dart)
- [settings_provider.dart](smartpocket/lib/presentation/providers/settings_provider.dart)
- [theme_mode_provider.dart](smartpocket/lib/presentation/providers/theme_mode_provider.dart)

---

## الإشعارات والتذكيرات

تهيئة `flutter_local_notifications`، وتذكيرات للديون المستحقة قريباً، وتذكيرات/حوارات مرتبطة بالعناصر الدورية عبر المحرك.

**ملفات رئيسية:**

- [notification_service.dart](smartpocket/lib/core/services/notification_service.dart)
- [debt_reminder_service.dart](smartpocket/lib/core/services/debt_reminder_service.dart)
- [recurring_engine_service.dart](smartpocket/lib/core/services/recurring_engine_service.dart)
- [main_shell_screen.dart](smartpocket/lib/presentation/screens/main_shell_screen.dart)

**اعتماديات ذات صلة:** `flutter_local_notifications` في [pubspec.yaml](smartpocket/pubspec.yaml)

---

## السمة والمظهر (Theme)

سمات فاتحة وداكنة عبر `AppTheme`، و`themeMode` من Riverpod؛ اللغة الافتراضية للتطبيق العربية مع دعم محلي إضافي في القائمة.

**ملفات رئيسية:**

- [app.dart](smartpocket/lib/app.dart)
- [app_theme.dart](smartpocket/lib/core/theme/app_theme.dart)
- [theme_mode_provider.dart](smartpocket/lib/presentation/providers/theme_mode_provider.dart)

---

## الرصيد والرؤى الذكية

حساب لقطة رصيد تدمج الرصيد الافتتاحي والتدفقات والديون؛ توليد رسائل رؤى (`SmartInsight`) للعرض في لوحة التحكم.

**ملفات رئيسية:**

- [balance_repository.dart](smartpocket/lib/domain/repositories/balance_repository.dart)
- [balance_repository_impl.dart](smartpocket/lib/data/repositories/balance_repository_impl.dart)
- [balance_snapshot.dart](smartpocket/lib/domain/entities/balance_snapshot.dart)
- [smart_insight.dart](smartpocket/lib/domain/entities/smart_insight.dart)
- [balance_provider.dart](smartpocket/lib/presentation/providers/balance_provider.dart)

---

## مساعدات العرض المالي

تنسيق العملات للواجهة، تحليل المبالغ من حقول النص، وإبطال مزوّدات Riverpod بعد تعديلات مالية لضمان تحديث الواجهة.

**ملفات رئيسية:**

- [money_format.dart](smartpocket/lib/presentation/utils/money_format.dart)
- [finance_currency.dart](smartpocket/lib/presentation/utils/finance_currency.dart)
- [amount_parser.dart](smartpocket/lib/presentation/utils/amount_parser.dart)
- [invalidate_finance.dart](smartpocket/lib/presentation/utils/invalidate_finance.dart)

---

## حقن التبعيات (Riverpod)

ربط مركزي بين مصادر البيانات المحلية، تنفيذات المستودعات، وخدمة تصدير التقارير.

**ملف رئيسي:**

- [repository_providers.dart](smartpocket/lib/presentation/providers/repository_providers.dart)

---

## ملاحظات وما قد يحتاج توضيحاً لاحقاً

- **إدارة الفئات من الواجهة:** الطبقة الخلفية تدعم مستودع الفئات، لكن لا توجد شاشة مخصصة لـ CRUD كامل للفئات المخصصة بنفس شكل شاشات الدخل/الديون؛ الاعتماد الفعلي على الفئات المزروعة والتفاصيل ضمن تدفق المصاريف.
- **`budget_alert_period` في الإعدادات العامة:** الحقل موجود في نموذج الإعدادات وقاعدة البيانات؛ ضبط فترة التنبيه لكل ميزانية فئة يظهر في سياق تفاصيل الفئة، بينما قد لا يكون هناك عنصر واجهة صريح في شاشة الإعدادات لتغيير القيمة العامة فقط — يُنصح بمراجعة [settings_screen.dart](smartpocket/lib/presentation/screens/settings_screen.dart) و [category_details_screen.dart](smartpocket/lib/presentation/screens/category_details_screen.dart) عند التطوير القادم.

---

## ملحق: هيكل مجلد `lib/`

```
lib/
├── app.dart
├── main.dart
├── core/           # قاعدة البيانات، التوجيه، الثوابت، السمة، الخدمات الأساسية
├── data/           # نماذج، مصادر محلية، مستودعات، خدمات (مثل تصدير التقارير)
├── domain/         # كيانات، عقود مستودعات، كائنات قيمة
└── presentation/   # شاشات، مزوّدات Riverpod، ويدجت، أدوات واجهة
```

---

*آخر تحديث للتوثيق يتزامن مع إصدار قاعدة البيانات **v8** والمسارات المعرفة في `app_router.dart`.*
