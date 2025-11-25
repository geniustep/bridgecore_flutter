# 🚀 BridgeCore Webhooks, Triggers & Real-time Updates Guide

## نظرة عامة

تم إضافة نظام شامل للأحداث (Events)، Webhooks، Triggers، وفحص التحديثات (Update Check) إلى BridgeCore Flutter SDK.

---

## 📋 جدول المحتويات

1. [Event Bus System](#1-event-bus-system)
2. [Webhook System](#2-webhook-system)
3. [Sync & Update Check System](#3-sync--update-check-system)
4. [Notification System](#4-notification-system)
5. [Trigger System](#5-trigger-system)
6. [Polling Service](#6-polling-service)
7. [WebSocket Service](#7-websocket-service-اختياري)
8. [أمثلة كاملة](#8-أمثلة-كاملة)

---

## 1. Event Bus System

### المفهوم
نظام أحداث مركزي يسمح للمكونات المختلفة بالتواصل عبر الأحداث.

### الاستخدام الأساسي

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  // الحصول على Event Bus
  final eventBus = BridgeCoreEventBus.instance;

  // الاستماع لحدث معين
  eventBus.on('auth.login').listen((event) {
    print('User logged in: ${event.data['user_id']}');
  });

  // إرسال حدث
  eventBus.emit('auth.login', {
    'user_id': 123,
    'username': 'john_doe',
  });
}
```

### أنواع الأحداث المتاحة

#### Authentication Events
- `auth.login` - تسجيل دخول
- `auth.logout` - تسجيل خروج
- `auth.token_refreshed` - تحديث التوكن
- `auth.session_expired` - انتهاء الجلسة

#### Odoo Record Events
- `odoo.record_created` - إنشاء سجل جديد
- `odoo.record_updated` - تحديث سجل
- `odoo.record_deleted` - حذف سجل
- `odoo.batch_completed` - إتمام عملية دفعية

#### Webhook Events
- `webhook.received` - استقبال webhook
- `webhook.registered` - تسجيل webhook
- `webhook.unregistered` - إلغاء تسجيل webhook

#### Sync Events
- `updates.available` - تحديثات متاحة
- `sync.started` - بدء المزامنة
- `sync.completed` - إتمام المزامنة
- `sync.progress` - تقدم المزامنة
- `sync.failed` - فشل المزامنة

### الميزات المتقدمة

#### 1. الاستماع لأحداث متعددة

```dart
// الاستماع لأي حدث auth
eventBus.onPattern('auth.').listen((event) {
  print('Auth event: ${event.type}');
});

// الاستماع لأحداث محددة
eventBus.onAny(['auth.login', 'auth.logout']).listen((event) {
  print('User auth change: ${event.type}');
});
```

#### 2. Event Filters

```dart
// تصفية الأحداث
eventBus.addFilter('odoo.record_created', (event) {
  // فقط أحداث sale.order
  return event.data['model'] == 'sale.order';
});
```

#### 3. Event Interceptors

```dart
// تعديل الأحداث قبل الإرسال
eventBus.addInterceptor((event) {
  return BridgeCoreEvent(
    type: event.type,
    data: {
      ...event.data,
      'intercepted_at': DateTime.now().toIso8601String(),
    },
  );
});
```

#### 4. انتظار حدث معين

```dart
// انتظار حدث معين (مع timeout)
final event = await eventBus.waitFor(
  'auth.login',
  timeout: Duration(seconds: 5),
);
print('Login successful: ${event.data}');
```

#### 5. Request-Response Pattern

```dart
// إرسال حدث وانتظار الرد
final response = await eventBus.emitAndWait(
  'sync.start',
  {},
  responseType: 'sync.completed',
  timeout: Duration(seconds: 30),
);
```

---

## 2. Webhook System

### المفهوم
نظام لتسجيل واستقبال webhooks من Odoo عند حدوث أحداث معينة.

### التسجيل الأساسي

```dart
final webhooks = BridgeCore.instance.webhooks;

// تسجيل webhook
final webhook = await webhooks.register(
  model: 'sale.order',
  event: 'create',
  callbackUrl: 'https://myapp.com/webhooks/sale-order-created',
  filters: {
    'state': ['=', 'draft'],
  },
);

print('Webhook registered: ${webhook.id}');
```

### أنواع الأحداث

- `create` - إنشاء سجل جديد
- `write` - تحديث سجل
- `unlink` - حذف سجل

### الاستقبال والمعالجة

```dart
// في server endpoint الخاص بك
void handleWebhookRequest(Map<String, dynamic> payload) {
  webhooks.handleIncoming(payload);
}

// الاستماع للأحداث
BridgeCoreEventBus.instance.on('webhook.received').listen((event) {
  print('Model: ${event.data['model']}');
  print('Event: ${event.data['event']}');
  print('Record ID: ${event.data['record_id']}');
  print('Data: ${event.data['data']}');
});
```

### إدارة Webhooks

```dart
// الحصول على جميع webhooks
final allWebhooks = await webhooks.list();

// تصفية webhooks
final salesWebhooks = await webhooks.list(
  model: 'sale.order',
  active: true,
);

// تحديث webhook
await webhooks.update(
  webhookId: 'webhook_123',
  active: false,
);

// إلغاء تسجيل webhook
await webhooks.unregister('webhook_123');

// اختبار webhook
final testLog = await webhooks.test('webhook_123');
print('Test status: ${testLog.status}');

// الحصول على سجلات التسليم
final logs = await webhooks.getLogs('webhook_123', limit: 50);
for (var log in logs) {
  print('Attempt ${log.attemptNumber}: ${log.status}');
}
```

### Convenience Methods

```dart
// تسجيل سريع للأحداث الشائعة
await webhooks.onCreate(
  model: 'sale.order',
  callbackUrl: 'https://myapp.com/webhooks/order-created',
);

await webhooks.onUpdate(
  model: 'product.product',
  callbackUrl: 'https://myapp.com/webhooks/product-updated',
);

await webhooks.onDelete(
  model: 'res.partner',
  callbackUrl: 'https://myapp.com/webhooks/partner-deleted',
);
```

### إحصائيات Webhooks

```dart
final stats = webhooks.getStatistics();
print('Total webhooks: ${stats['total']}');
print('Active: ${stats['active']}');
print('By model: ${stats['by_model']}');
print('By event: ${stats['by_event']}');
```

---

## 3. Sync & Update Check System

### المفهوم
نظام لفحص التحديثات المتاحة والمزامنة الكاملة للبيانات.

### 🔥 فحص سريع للتحديثات (hasUpdates)

```dart
final sync = BridgeCore.instance.sync;

// فحص سريع - هذه هي الدالة المطلوبة!
if (await sync.hasUpdates()) {
  print('تحديثات متاحة!');
  showUpdateNotification();
}
```

### الحصول على تفاصيل التحديثات

```dart
// معلومات مفصلة عن التحديثات
final updates = await sync.getUpdatesInfo();

print('عدد التحديثات: ${updates.updateCount}');
print('آخر مزامنة: ${updates.lastSync}');

// التحديثات حسب النموذج
for (var entry in updates.modelUpdates.entries) {
  final model = entry.key;
  final modelUpdate = entry.value;

  print('$model:');
  print('  - سجلات جديدة: ${modelUpdate.newRecords}');
  print('  - سجلات محدثة: ${modelUpdate.updatedRecords}');
  print('  - سجلات محذوفة: ${modelUpdate.deletedRecords}');
}
```

### فحص نموذج معين

```dart
// فحص تحديثات نموذج محدد
final orderUpdates = await sync.checkModelUpdates(
  model: 'sale.order',
  lastSync: DateTime.now().subtract(Duration(hours: 1)),
);

if (orderUpdates.hasChanges) {
  print('${orderUpdates.newRecords} طلبات جديدة');
  print('${orderUpdates.updatedRecords} طلبات محدثة');

  // معرفات السجلات الجديدة
  print('IDs: ${orderUpdates.newIds}');
}
```

### المزامنة الكاملة

```dart
// بدء مزامنة كاملة
await sync.startSync(
  models: ['sale.order', 'product.product', 'res.partner'],
  forceRefresh: false,
);

// مراقبة التقدم
sync.monitorSyncProgress(
  pollInterval: Duration(seconds: 2),
  onProgress: (status) {
    print('التقدم: ${status.progressPercentage}%');
    print('المرحلة الحالية: ${status.currentStage}');
    print('السجلات: ${status.syncedItems}/${status.totalItems}');
  },
);

// أو الاستماع للأحداث
BridgeCoreEventBus.instance.on('sync.progress').listen((event) {
  print('Progress: ${event.data['progress_percentage']}%');
});

BridgeCoreEventBus.instance.on('sync.completed').listen((event) {
  print('المزامنة اكتملت!');
});
```

### الفحص الدوري التلقائي

```dart
// بدء فحص تلقائي كل 5 دقائق
sync.startPeriodicUpdateCheck(
  interval: Duration(minutes: 5),
);

// الاستماع للتحديثات
BridgeCoreEventBus.instance.on('updates.available').listen((event) {
  showUpdateNotification();
});

// إيقاف الفحص التلقائي
sync.stopPeriodicUpdateCheck();
```

### الحصول على حالة المزامنة

```dart
// الحالة الحالية
final status = await sync.getStatus();

if (status.isRunning) {
  print('المزامنة جارية: ${status.progressPercentage}%');
  print('الوقت المتبقي: ${status.remainingTime}');
} else {
  print('آخر مزامنة: ${status.lastSuccessfulSync}');
}
```

### سجل المزامنة

```dart
// الحصول على سجل المزامنات السابقة
final history = await sync.getHistory(limit: 10);

for (var entry in history) {
  print('${entry.startedAt}: ${entry.status}');
  print('  - سجلات: ${entry.recordsSynced}');
  print('  - أخطاء: ${entry.errorCount}');
  print('  - المدة: ${entry.duration}');
}
```

### إلغاء المزامنة

```dart
// إلغاء مزامنة جارية
await sync.cancelSync();
```

---

## 4. Notification System

### المفهوم
نظام لإدارة الإشعارات بناءً على الأحداث.

### الإعداد الأساسي

```dart
final notifications = BridgeCore.instance.notifications;

// إضافة قاعدة إشعار
notifications.addRule(
  NotificationRule(
    eventType: 'odoo.record_created',
    condition: (event) {
      return event.data['model'] == 'sale.order';
    },
    builder: (event) {
      return AppNotification(
        title: 'طلب مبيعات جديد',
        body: 'تم إنشاء طلب رقم ${event.data['id']}',
        data: event.data,
      );
    },
  ),
);
```

### إدارة الإشعارات

```dart
// الحصول على الإشعارات
final notificationsList = await notifications.list(
  unreadOnly: true,
  limit: 20,
);

// وضع علامة مقروء
await notifications.markAsRead('notification_123');

// وضع علامة على الكل
await notifications.markAllAsRead();

// حذف إشعار
await notifications.delete('notification_123');
```

### تفضيلات الإشعارات

```dart
// الحصول على التفضيلات
final prefs = await notifications.getPreferences();

// تحديث التفضيلات
await notifications.updatePreferences({
  'enable_push': true,
  'enable_email': false,
  'sale_order_notifications': true,
  'product_notifications': false,
});
```

### Push Notifications

```dart
// تسجيل الجهاز
await notifications.registerDevice(
  deviceToken: 'fcm_device_token_here',
  platform: 'android', // or 'ios'
);

// إلغاء تسجيل الجهاز
await notifications.unregisterDevice('device_id');
```

---

## 5. Trigger System

### المفهوم
نظام لإنشاء triggers تنفذ أفعال معينة عند تحقق شروط.

### إنشاء Trigger

```dart
final triggers = BridgeCore.instance.triggers;

// إنشاء trigger للمخزون المنخفض
final trigger = await triggers.create(
  name: 'تنبيه المخزون المنخفض',
  model: 'product.product',
  condition: TriggerCondition(
    field: 'qty_available',
    operator: '<',
    value: 10,
  ),
  action: TriggerAction(
    type: 'notification',
    params: {
      'title': 'تحذير مخزون',
      'message': 'المخزون أقل من 10 وحدات',
      'priority': 'high',
    },
  ),
  active: true,
);
```

### أنواع الشروط

```dart
// شرط رقمي
TriggerCondition(
  field: 'total_amount',
  operator: '>',
  value: 10000,
)

// شرط نصي
TriggerCondition(
  field: 'state',
  operator: '==',
  value: 'sale',
)

// شرط يحتوي
TriggerCondition(
  field: 'name',
  operator: 'contains',
  value: 'urgent',
)
```

### أنواع الأفعال

```dart
// إرسال إشعار
TriggerAction(
  type: 'notification',
  params: {'title': '...', 'message': '...'},
)

// استدعاء webhook
TriggerAction(
  type: 'webhook',
  params: {'url': 'https://...', 'method': 'POST'},
)

// استدعاء method في Odoo
TriggerAction(
  type: 'method_call',
  params: {'method': 'action_confirm', 'model': 'sale.order'},
)

// إرسال بريد إلكتروني
TriggerAction(
  type: 'email',
  params: {
    'to': 'admin@company.com',
    'subject': '...',
    'body': '...',
  },
)
```

### إدارة Triggers

```dart
// قائمة جميع triggers
final triggersList = await triggers.list();

// الحصول على trigger
final trigger = await triggers.get('trigger_123');

// تحديث trigger
await triggers.update(
  triggerId: 'trigger_123',
  active: false,
);

// حذف trigger
await triggers.delete('trigger_123');

// تفعيل/تعطيل
await triggers.toggle('trigger_123');
```

### تنفيذ يدوي

```dart
// تنفيذ trigger يدوياً
await triggers.execute('trigger_123', {
  'record_id': 123,
  'model': 'sale.order',
});
```

### سجل التنفيذ

```dart
// الحصول على سجل التنفيذ
final history = await triggers.getHistory('trigger_123');

for (var entry in history) {
  print('${entry.executedAt}: ${entry.status}');
  print('Result: ${entry.result}');
}
```

---

## 6. Polling Service

### المفهوم
فحص دوري للتغييرات (بديل للـ webhooks عندما لا تكون متاحة).

### الاستخدام الأساسي

```dart
final polling = BridgeCore.instance.polling;

// بدء polling لنموذج معين
final pollerId = polling.start(
  model: 'sale.order',
  domain: [['state', '=', 'draft']],
  interval: Duration(seconds: 30),
  fetchData: () async {
    return await BridgeCore.instance.odoo.searchRead(
      model: 'sale.order',
      domain: [['state', '=', 'draft']],
      fields: ['name', 'partner_id', 'amount_total'],
    );
  },
);

// الاستماع للتغييرات
BridgeCoreEventBus.instance.on('polling.change_detected').listen((event) {
  print('Change type: ${event.data['change_type']}');
  print('Record: ${event.data['record']}');
});

// إيقاف polling
polling.stop(pollerId);
```

---

## 7. WebSocket Service (اختياري)

### المفهوم
اتصال real-time عبر WebSocket لتحديثات فورية.

### الاتصال

```dart
final websocket = BridgeCore.instance.websocket;

// الاتصال
await websocket.connect();

// الاستماع للرسائل
BridgeCoreEventBus.instance.on('websocket.message').listen((event) {
  print('Message: ${event.data}');
});

// الاشتراك في نموذج
websocket.subscribeToModel('sale.order', recordIds: [1, 2, 3]);

// إرسال رسالة
websocket.send('ping', {'timestamp': DateTime.now().toIso8601String()});

// قطع الاتصال
websocket.disconnect();
```

---

## 8. أمثلة كاملة

### مثال 1: نظام إشعارات متكامل للطلبات

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

Future<void> setupOrderNotifications() async {
  final eventBus = BridgeCoreEventBus.instance;
  final webhooks = BridgeCore.instance.webhooks;
  final notifications = BridgeCore.instance.notifications;

  // 1. تسجيل webhook لطلبات المبيعات الجديدة
  await webhooks.onCreate(
    model: 'sale.order',
    callbackUrl: 'https://myapp.com/webhooks/new-order',
  );

  // 2. إضافة قاعدة إشعار
  notifications.addRule(
    NotificationRule(
      eventType: 'odoo.record_created',
      condition: (event) => event.data['model'] == 'sale.order',
      builder: (event) => AppNotification(
        title: 'طلب مبيعات جديد 🎉',
        body: 'تم استلام طلب جديد بقيمة ${event.data['data']['amount_total']}',
        data: event.data,
      ),
    ),
  );

  // 3. الاستماع للأحداث
  eventBus.on('odoo.record_created').listen((event) {
    if (event.data['model'] == 'sale.order') {
      print('New order #${event.data['id']}');

      // تحديث UI
      updateOrdersList();

      // إرسال إحصائيات
      sendAnalytics('new_order', event.data);
    }
  });

  print('نظام الإشعارات جاهز!');
}
```

### مثال 2: فحص تحديثات تلقائي مع إشعارات

```dart
Future<void> setupAutoUpdateCheck() async {
  final sync = BridgeCore.instance.sync;
  final eventBus = BridgeCoreEventBus.instance;

  // بدء فحص دوري كل 5 دقائق
  sync.startPeriodicUpdateCheck(
    interval: Duration(minutes: 5),
  );

  // عند توفر تحديثات
  eventBus.on('updates.available').listen((event) async {
    // الحصول على التفاصيل
    final updates = await sync.getUpdatesInfo();

    // عرض إشعار
    showNotificationDialog(
      title: 'تحديثات متاحة',
      message: '${updates.updateCount} تحديث متاح',
      actions: [
        TextButton(
          child: Text('تحديث الآن'),
          onPressed: () async {
            // بدء المزامنة
            await sync.startSync();

            // مراقبة التقدم
            await sync.monitorSyncProgress(
              onProgress: (status) {
                updateProgressBar(status.progress);
              },
            );

            print('المزامنة اكتملت!');
          },
        ),
      ],
    );
  });
}
```

### مثال 3: نظام triggers للمخزون

```dart
Future<void> setupInventoryTriggers() async {
  final triggers = BridgeCore.instance.triggers;

  // Trigger 1: تنبيه عند انخفاض المخزون
  await triggers.create(
    name: 'مخزون منخفض',
    model: 'product.product',
    condition: TriggerCondition(
      field: 'qty_available',
      operator: '<',
      value: 10,
    ),
    action: TriggerAction(
      type: 'notification',
      params: {
        'title': '⚠️ تحذير مخزون',
        'message': 'المخزون أقل من 10 وحدات',
        'priority': 'high',
      },
    ),
  );

  // Trigger 2: تنبيه عند نفاذ المخزون
  await triggers.create(
    name: 'نفاذ المخزون',
    model: 'product.product',
    condition: TriggerCondition(
      field: 'qty_available',
      operator: '<=',
      value: 0,
    ),
    action: TriggerAction(
      type: 'email',
      params: {
        'to': 'manager@company.com',
        'subject': 'نفاذ مخزون منتج',
        'body': 'المنتج {{product_name}} نفذ من المخزون',
      },
    ),
  );

  // Trigger 3: طلب تلقائي عند الوصول للحد الأدنى
  await triggers.create(
    name: 'طلب تلقائي',
    model: 'product.product',
    condition: TriggerCondition(
      field: 'qty_available',
      operator: '<=',
      value: 5,
    ),
    action: TriggerAction(
      type: 'method_call',
      params: {
        'model': 'purchase.order',
        'method': 'create_auto_order',
        'args': [{'product_id': '{{product_id}}', 'quantity': 50}],
      },
    ),
  );

  print('تم إعداد ${3} triggers للمخزون');
}
```

### مثال 4: نظام متكامل كامل

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class OrderManagementSystem {
  late WebhookService webhooks;
  late SyncService sync;
  late NotificationService notifications;
  late TriggerService triggers;
  final eventBus = BridgeCoreEventBus.instance;

  Future<void> initialize() async {
    webhooks = BridgeCore.instance.webhooks;
    sync = BridgeCore.instance.sync;
    notifications = BridgeCore.instance.notifications;
    triggers = BridgeCore.instance.triggers;

    await _setupWebhooks();
    await _setupTriggers();
    await _setupNotifications();
    await _setupAutoSync();

    print('✅ نظام إدارة الطلبات جاهز!');
  }

  Future<void> _setupWebhooks() async {
    // webhook لطلبات جديدة
    await webhooks.onCreate(
      model: 'sale.order',
      callbackUrl: 'https://myapp.com/webhooks/order-created',
    );

    // webhook لتحديثات الطلبات
    await webhooks.onUpdate(
      model: 'sale.order',
      callbackUrl: 'https://myapp.com/webhooks/order-updated',
      filters: {'state': ['in', ['sale', 'done']]},
    );
  }

  Future<void> _setupTriggers() async {
    // trigger للطلبات الكبيرة
    await triggers.create(
      name: 'طلب كبير',
      model: 'sale.order',
      condition: TriggerCondition(
        field: 'amount_total',
        operator: '>',
        value: 50000,
      ),
      action: TriggerAction(
        type: 'notification',
        params: {
          'title': '🎯 طلب كبير',
          'message': 'طلب بقيمة أكثر من 50,000',
          'priority': 'urgent',
        },
      ),
    );
  }

  Future<void> _setupNotifications() async {
    notifications.addRule(
      NotificationRule(
        eventType: 'odoo.record_created',
        condition: (event) => event.data['model'] == 'sale.order',
        builder: (event) => AppNotification(
          title: 'طلب جديد',
          body: 'طلب #${event.data['id']}',
          data: event.data,
        ),
      ),
    );
  }

  Future<void> _setupAutoSync() async {
    // فحص تلقائي كل 3 دقائق
    sync.startPeriodicUpdateCheck(
      interval: Duration(minutes: 3),
    );

    // عند توفر تحديثات، قم بالمزامنة
    eventBus.on('updates.available').listen((_) async {
      final updates = await sync.getUpdatesInfo();

      if (updates.updateCount > 0) {
        await sync.startSync(
          models: ['sale.order', 'stock.picking'],
        );
      }
    });
  }

  void dispose() {
    sync.stopPeriodicUpdateCheck();
  }
}

// الاستخدام في main.dart
void main() async {
  BridgeCore.initialize(
    baseUrl: 'https://api.yourcompany.com',
    debugMode: true,
  );

  final system = OrderManagementSystem();
  await system.initialize();

  runApp(MyApp());
}
```

---

## 📊 Endpoints المضافة

تم إضافة 40+ endpoint جديد في `lib/src/core/endpoints.dart`:

### Webhook Endpoints
- `POST /api/v1/webhooks/register`
- `DELETE /api/v1/webhooks/{id}`
- `GET /api/v1/webhooks/list`
- `GET /api/v1/webhooks/{id}`
- `PUT /api/v1/webhooks/{id}`
- `POST /api/v1/webhooks/{id}/test`
- `GET /api/v1/webhooks/{id}/logs`

### Sync & Update Endpoints
- `GET /api/v1/sync/check-updates` ⭐
- `GET /api/v1/sync/updates-info`
- `POST /api/v1/sync/check-model-updates`
- `GET /api/v1/sync/status`
- `POST /api/v1/sync/start`
- `GET /api/v1/sync/history`
- `POST /api/v1/sync/cancel`

### Trigger Endpoints
- `POST /api/v1/triggers/create`
- `GET /api/v1/triggers/list`
- `GET /api/v1/triggers/{id}`
- `PUT /api/v1/triggers/{id}`
- `DELETE /api/v1/triggers/{id}`
- `POST /api/v1/triggers/{id}/toggle`
- `GET /api/v1/triggers/{id}/history`
- `POST /api/v1/triggers/{id}/execute`

### Notification Endpoints
- `GET /api/v1/notifications/list`
- `POST /api/v1/notifications/{id}/read`
- `POST /api/v1/notifications/read-all`
- `DELETE /api/v1/notifications/{id}`
- `GET /api/v1/notifications/preferences`
- `PUT /api/v1/notifications/preferences`
- `POST /api/v1/notifications/register-device`
- `POST /api/v1/notifications/unregister-device`

---

## 🎯 الميزات الرئيسية

### ✅ تم إنجازه

1. **Event Bus System** ✅
   - نظام أحداث مركزي
   - 40+ نوع حدث
   - Filters و Interceptors
   - Wait for events
   - Request-Response pattern

2. **Webhook System** ✅
   - تسجيل webhooks
   - استقبال ومعالجة webhooks
   - إدارة كاملة (list, update, delete)
   - سجلات التسليم
   - اختبار webhooks

3. **Sync & Update Check** ✅
   - `hasUpdates()` - فحص سريع ⭐
   - معلومات تفصيلية عن التحديثات
   - فحص حسب النموذج
   - مزامنة كاملة
   - فحص دوري تلقائي
   - مراقبة التقدم
   - سجل المزامنة

4. **40+ Endpoints جديدة** ✅
   - جميع endpoints مضافة في `endpoints.dart`
   - موثقة بالكامل
   - جاهزة للاستخدام

---

## 🚀 البدء السريع

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() async {
  // 1. التهيئة
  BridgeCore.initialize(
    baseUrl: 'https://api.yourcompany.com',
    debugMode: true,
  );

  // 2. تسجيل الدخول
  await BridgeCore.instance.auth.login(
    email: 'user@company.com',
    password: 'password',
  );

  // 3. فحص التحديثات
  final sync = BridgeCore.instance.sync;
  if (await sync.hasUpdates()) {
    print('تحديثات متاحة!');
  }

  // 4. تسجيل webhook
  final webhooks = BridgeCore.instance.webhooks;
  await webhooks.onCreate(
    model: 'sale.order',
    callbackUrl: 'https://myapp.com/webhooks/order',
  );

  // 5. الاستماع للأحداث
  BridgeCoreEventBus.instance.on('odoo.record_created').listen((event) {
    print('New record: ${event.data}');
  });

  runApp(MyApp());
}
```

---

## 📚 الملفات المضافة

### Events
- `lib/src/events/bridgecore_event.dart`
- `lib/src/events/event_types.dart`
- `lib/src/events/event_bus.dart`

### Webhooks
- `lib/src/webhooks/webhook_service.dart`
- `lib/src/webhooks/models/webhook_registration.dart`
- `lib/src/webhooks/models/webhook_payload.dart`
- `lib/src/webhooks/models/webhook_delivery_log.dart`

### Sync
- `lib/src/sync/sync_service.dart`
- `lib/src/sync/models/updates_info.dart`
- `lib/src/sync/models/sync_status.dart`
- `lib/src/sync/models/sync_history.dart`

### Endpoints
- `lib/src/core/endpoints.dart` (محدّث)

---

## 🎓 التوثيق الإضافي

للمزيد من المعلومات، راجع:
- `README.md` - الدليل الرئيسي
- `CHANGELOG.md` - سجل التغييرات
- `examples/` - أمثلة كاملة

---

## 💡 نصائح مهمة

1. **استخدم الفحص الدوري** - `startPeriodicUpdateCheck()` للحصول على تحديثات تلقائية
2. **استمع للأحداث** - Event Bus يجعل التطبيق reactive
3. **استخدم Webhooks** - أسرع من polling
4. **راقب الأخطاء** - استخدم try-catch لجميع العمليات
5. **نظف الموارد** - استخدم `dispose()` عند الانتهاء

---

تم بناؤه بـ ❤️ لمجتمع Odoo & Flutter

**الإصدار:** 3.1.0
**التاريخ:** 2025-11-25
