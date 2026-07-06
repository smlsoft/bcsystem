# GitHub Copilot Instructions for DedeCashier Project

## 🚫 ข้อห้าม (Prohibited Actions)

### 1. ห้ามสร้างไฟล์ Markdown โดยไม่จำเป็น
- ❌ **ห้าม** สร้างไฟล์ `.md` ใหม่เว้นแต่ได้รับอนุญาตชัดเจน
- ❌ **ห้าม** สร้าง documentation files โดยไม่ได้ขอ
- ✅ **ยกเว้น** การอัพเดทไฟล์ README.md ที่มีอยู่แล้วเมื่อได้รับคำสั่ง
- ⭐ **เพิ่มเติม** ใช้ comments ในโค้ดแทนการสร้างไฟล์ .md

### 2. ห้ามแก้ไข Business Logic โดยพลการ
- ❌ **ห้าม** เปลี่ยนแปลง logic การคำนวณ
- ❌ **ห้าม** เปลี่ยนแปลง flow การทำงานหลัก
- ❌ **ห้าม** ลบ features ที่มีอยู่
- ✅ **อนุญาต** เฉพาะการ optimize performance โดยไม่เปลี่ยน output
- ⭐ **บังคับ** ต้องทดสอบว่า output/behavior เหมือนเดิม 100%

### 3. ห้ามแก้ไข Code โดยไม่ถามก่อน
- ❌ **ห้าม** แก้ไขโค้ดทันที
- ✅ **ต้องถามทุกครั้ง** และรอการอนุมัติ
- ✅ **แสดงแผนก่อน** พร้อมอธิบายผลกระทบ
- ⭐ **บังคับ** ต้องค้นหาวิธีแก้จาก Internet/Documentation ก่อนเสนอ

## ✅ หน้าที่หลัก (Primary Responsibilities)

### 1. Performance Optimization
**เป้าหมาย: ปรับปรุงความเร็วโดยไม่กระทบการทำงานเดิม**

#### Code Optimization Priorities:
1. **Async Operations** (สำคัญที่สุด)
   - แปลง sync operations เป็น async
   - ใช้ `Future.wait()` สำหรับ parallel processing
   - หลีกเลี่ยง blocking operations

2. **Caching**
   - ใช้ Map cache สำหรับ repeated lookups
   - Cache computed values ที่ไม่เปลี่ยน
   - Precache images และ assets

3. **Widget Optimization**
   - ใช้ `const` constructor ทุกที่ที่เป็นไปได้
   - ใช้ `AnimatedBuilder` แทน `addListener()`
   - ใช้ `ValueListenableBuilder` แทน global `setState()`
   - Extract widgets ที่ rebuild บ่อยเป็น separate widgets

4. **Algorithm Optimization**
   - ใช้ `indexWhere()` แทน manual loops
   - ใช้ Regex แทน nested string operations
   - ใช้ `whereType()` แทน manual type checking

5. **Resource Management**
   - Dispose controllers, streams, และ listeners
   - Close connections เมื่อไม่ใช้
   - Cancel timers และ animations

6. **⭐ Performance Logging (Debug Mode Only)**
   - เพิ่ม performance logs เพื่อวัดเวลาการทำงานของ functions
   - ใช้ `Stopwatch` หรือ `Timeline` API
   - Log ต้องทำงานใน `kDebugMode` เท่านั้น
   - ไม่มี logs ใน Release/Production builds

#### Performance Logging Pattern:
```dart
// ✅ GOOD - Performance logging in debug mode
Future<void> expensiveOperation() async {
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }
  
  // ... actual work ...
  await processData();
  
  if (kDebugMode) {
    stopwatch?.stop();
    print('[Performance] expensiveOperation took ${stopwatch?.elapsedMilliseconds}ms');
  }
}

// ❌ BAD - Logs in production
Future<void> expensiveOperation() async {
  final stopwatch = Stopwatch()..start();
  await processData();
  print('Took ${stopwatch.elapsedMilliseconds}ms'); // ทำงานใน production!
}
```

### 2. UI/UX Smoothness & Visual Design
**เป้าหมาย: หน้าจอเลื่อนไหลไม่สะดุด และดูสวยงาม**

#### UI/UX Excellence:
1. **Visual Design Principles**
   - ใช้ Material Design 3 guidelines
   - สี: ใช้ theme color palette สม่ำเสมอ
   - Typography: ขนาดตัวอักษรที่เหมาะสม (14-16px body, 20-24px header)
   - Spacing: ใช้ 8px grid system (8, 16, 24, 32px)
   - Elevation: ใช้ shadows และ elevation อย่างเหมาะสม
   - Border Radius: 8-16px สำหรับ modern look
   - Icons: ใช้ Material Icons ที่เหมาะสมกับ context

2. **Animation & Transitions**
   - Smooth transitions (200-300ms)
   - ใช้ Curves.easeInOut สำหรับ natural feel
   - Hero animations สำหรับ navigation
   - Micro-interactions เพื่อ feedback

3. **Responsive Design**
   - รองรับหลายขนาดหน้าจอ
   - Breakpoints สำหรับ tablet/desktop
   - Flexible layouts ด้วย Flex/Expanded

#### Smoothness Rules:
1. **ไม่มี UI Blocking**
   - ❌ ห้ามใช้ `Future.delayed()` เกิน 100ms ใน main thread
   - ❌ ห้ามใช้ sync file I/O
   - ❌ ห้าม heavy computation ใน build()

2. **setState() Management**
   - ใช้ `setState()` เฉพาะส่วนที่จำเป็น
   - แยก state ออกเป็น smaller widgets
   - ใช้ `ValueNotifier` สำหรับ local state

3. **Animation Best Practices**
   - ใช้ `AnimationController` ที่ dispose ถูกต้อง
   - หลีกเลี่ยง animation loops ที่ไม่จำเป็น
   - ใช้ `AnimatedBuilder` เพื่อ limit rebuilds

4. **List Performance**
   - ใช้ `ListView.builder` สำหรับ long lists
   - ใช้ `const` ใน list items
   - Cache list item widgets

### 3. Code Analysis & Weakness Detection
**เป้าหมาย: วิเคราะห์และแนะนำจุดอ่อน**

#### ต้องวิเคราะห์ทุกครั้งก่อนแก้ไข:
1. **Performance Bottlenecks**
   - Blocking operations
   - Nested loops
   - Redundant calculations
   - Memory leaks

2. **UI/UX Issues**
   - Janky animations
   - Slow page loads
   - Missing loading states
   - Poor error handling

3. **Code Quality**
   - Code duplication
   - Complex methods
   - Missing error handling
   - Resource management issues

4. **Security & Best Practices**
   - Hardcoded credentials
   - Missing input validation
   - Improper async handling
   - Missing null checks

### 4. Research-Based Solutions
**เป้าหมาย: ใช้ Best Practices จาก Internet**

#### ต้องอ้างอิง:
- Flutter Official Documentation
- Dart Language Specification
- Material Design Guidelines
- Performance Best Practices
- Community-proven patterns

#### Smoothness Rules:
1. **ไม่มี UI Blocking**
   - ❌ ห้ามใช้ `Future.delayed()` เกิน 100ms ใน main thread
   - ❌ ห้ามใช้ sync file I/O
   - ❌ ห้าม heavy computation ใน build()

2. **setState() Management**
   - ใช้ `setState()` เฉพาะส่วนที่จำเป็น
   - แยก state ออกเป็น smaller widgets
   - ใช้ `ValueNotifier` สำหรับ local state

3. **Animation Best Practices**
   - ใช้ `AnimationController` ที่ dispose ถูกต้อง
   - หลีกเลี่ยง animation loops ที่ไม่จำเป็น
   - ใช้ `AnimatedBuilder` เพื่อ limit rebuilds

4. **List Performance**
   - ใช้ `ListView.builder` สำหรับ long lists
   - ใช้ `const` ใน list items
   - Cache list item widgets

### 3. Code Quality Standards

#### Always Apply:
```dart
// ✅ GOOD - Async with error handling
Future<void> loadData() async {
  try {
    await Future.wait([
      loadConfig(),
      loadEmployee(),
    ]);
  } catch (e) {
    if (kDebugMode) print('Error: $e');
  }
}

// ❌ BAD - Blocking with delays
Future<void> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  await loadConfig();
  await loadEmployee();
}
```

```dart
// ✅ GOOD - Optimized lookup with cache
final Map<String, String> _cache = {};

String getValue(String key) {
  return _cache[key] ?? _computeAndCache(key);
}

// ❌ BAD - Linear search every time
String getValue(String key) {
  for (var item in items) {
    if (item.key == key) return item.value;
  }
  return '';
}
```

```dart
// ✅ GOOD - Minimal rebuilds
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counter,
      builder: (context, value, child) {
        return Text('$value');
      },
    );
  }
}

// ❌ BAD - Rebuilds everything
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void updateCounter() {
    setState(() {
      counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('$counter');
  }
}
```

## 🔄 Workflow Requirements

### Before Making ANY Code Changes:
1. **ASK FIRST** (ถามก่อนทุกครั้ง)
   - แสดงแผนการแก้ไขที่ชัดเจน
   - อธิบายว่าจะมีผลกระทบอย่างไร
   - รอการอนุมัติก่อนแก้ไข

2. **RESEARCH FIRST** (ค้นหาข้อมูลก่อนเสมอ)
   - ค้นหา best practices จาก Flutter/Dart documentation
   - อ้างอิง Material Design guidelines
   - ดู performance benchmarks
   - ตรวจสอบ community solutions

3. **ANALYZE WEAKNESSES** (วิเคราะห์จุดอ่อน)
   - ระบุ performance bottlenecks
   - หา code smells
   - ตรวจสอบ security issues
   - แนะนำการปรับปรุง

4. **Explain Impact**
   - Performance gain expected (%)
   - Potential risks
   - Alternative approaches

5. **Show Before/After**
   - แสดงโค้ดเดิมและโค้ดใหม่
   - อธิบายความแตกต่าง
   - Highlight breaking changes (ถ้ามี)

6. **⭐ Add Performance Logging**
   - เพิ่ม performance measurements ใน debug mode
   - วัดเวลาการทำงานของ functions ที่มีการแก้ไข
   - ใช้ `Stopwatch` หรือ `Timeline` API
   - Log ต้องอยู่ใน `if (kDebugMode) { ... }` เท่านั้น

### Example Response Format:
```
🔍 วิเคราะห์ปัญหา:
- ตรวจพบ: [ปัญหาที่พบ]
- สาเหตุ: [เหตุผล]
- ผลกระทบ: [ระดับความร้ายแรง]

✅ วิธีแก้ที่แนะนำ:
1. [วิธีที่ 1] - [ข้อดี/ข้อเสีย]
2. [วิธีที่ 2] - [ข้อดี/ข้อเสีย]

📊 ผลลัพธ์ที่คาดหวัง:
- ความเร็ว: [เพิ่มขึ้น X%]
- UX: [ปรับปรุงอย่างไร]
- Risks: [ความเสี่ยง]

❓ ต้องการให้ดำเนินการหรือไม่?
```

## 🎯 Optimization Patterns

### Pattern 1: Parallel Loading
```dart
// ✅ แนะนำ
await Future.wait([
  loadA(),
  loadB(),
  loadC().catchError((e) => print('Optional: $e')),
]);

// ❌ ห้าม
await loadA();
await loadB();
await loadC();
```

### Pattern 2: Lazy Loading
```dart
// ✅ แนะนำ - โหลดตอนใช้จริง
AudioSource? _getSound(SoundEnum sound) {
  _cache[sound] ??= _loadSound(sound);
  return _cache[sound];
}

// ❌ ห้าม - โหลดทั้งหมดตอนเริ่มต้น
void initSounds() {
  for (var sound in SoundEnum.values) {
    _cache[sound] = _loadSound(sound);
  }
}
```

### Pattern 3: Smart Caching
```dart
// ✅ แนะนำ - Cache with expiry
class SmartCache<K, V> {
  final Map<K, CacheEntry<V>> _cache = {};
  final Duration expiry;
  
  V? get(K key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.value;
    }
    return null;
  }
}

// ❌ ห้าม - Unlimited cache
final Map<String, dynamic> _cache = {};  // ไม่มี limit, ไม่มี expiry
```

### Pattern 4: Widget Composition
```dart
// ✅ แนะนำ - Extract และใช้ const
class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 24));
  }
}

// ❌ ห้าม - Build ในฟังก์ชัน
Widget _buildHeader(String title) {
  return Text(title, style: TextStyle(fontSize: 24));
}
```

## 📝 Code Review Checklist

Before suggesting any code change, verify:

- [ ] ✅ ไม่กระทบ business logic
- [ ] ✅ เพิ่มความเร็ว/ลื่นไหล
- [ ] ✅ ใช้ async ถูกต้อง
- [ ] ✅ มี error handling
- [ ] ✅ Dispose resources
- [ ] ✅ ใช้ const ทุกที่ที่เป็นไปได้
- [ ] ✅ ไม่มี memory leak
- [ ] ✅ Test แล้วทำงานเหมือนเดิม

## 🚨 Red Flags (สัญญาณเตือน)

**ห้ามทำสิ่งเหล่านี้:**

```dart
// ❌ Sync file operations
File(path).readAsStringSync();

// ❌ Blocking delays
await Future.delayed(Duration(seconds: 3));

// ❌ setState ใน addListener
animation.addListener(() {
  setState(() {});  // Rebuild ทั้งหน้าทุก frame!
});

// ❌ Empty setState
setState(() {});

// ❌ No mounted check after async
await someAsyncOperation();
setState(() {});  // อาจจะ crash!

// ❌ Nested loops with expensive operations
for (var i in list1) {
  for (var j in list2) {
    jsonDecode(i.data);  // O(n*m) + expensive!
  }
}
```

## 🎓 Learning Resources References

When suggesting optimizations, reference:
- Flutter Performance Best Practices
- Dart Async Programming Guide
- Widget Build Optimization Patterns
- Memory Management in Flutter
- Material Design Guidelines
- Flutter Animation Best Practices

## 🔧 Debug Mode Practices

```dart
// ✅ แนะนำ - Informative logs
if (kDebugMode) {
  print('[Component] 🚀 Action: details');
}

// ❌ ห้าม - Production prints
print('Debug info');  // จะทำงานใน production ด้วย
```

## 📐 Measurement Guidelines

**เมื่อ optimize ให้วัดผลเสมอ:**
- Before/After execution time
- Memory usage impact
- Frame rate (target: 60 FPS)
- Cold start time
- Hot reload time

## 🎯 Success Criteria

**Code change ถือว่าสำเร็จเมื่อ:**
1. ✅ ทำงานได้เหมือนเดิม 100%
2. ✅ เร็วขึ้นอย่างน้อย 10%
3. ✅ UI ลื่นไหลขึ้น (60 FPS)
4. ✅ ไม่มี memory leak
5. ✅ Code อ่านง่ายขึ้น
6. ✅ UI ดูสวยงามขึ้น
7. ✅ UX ดีขึ้น (responsive, accessible)

---

**สรุป: คิดก่อนแก้, ค้นคว้าก่อนทำ, ถามก่อนเปลี่ยน, วัดผลหลังเสร็จ** 🎯
