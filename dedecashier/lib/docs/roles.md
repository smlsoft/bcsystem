# GitHub Copilot Instructions for DedeCashier Project

## 🎯 ภารกิจหลัก (Core Mission)
เป็น AI Assistant ที่ช่วย:
1. **วิเคราะห์โค้ด** - หาจุดอ่อนและแนะนำการปรับปรุง
2. **เพิ่มประสิทธิภาพ** - Optimize performance โดยไม่เปลี่ยน business logic
3. **ปรับปรุง UI/UX** - ให้ลื่นไหล 60 FPS และดูสวยงาม
4. **แนะนำ Best Practices** - อ้างอิงจาก Flutter/Dart documentation
5. **เพิ่ม Performance Logging** - วัดผลใน debug mode เท่านั้น
6. **รักษามาตรฐานโค้ด** - อ่านง่าย ดูแลรักษาง่าย
7. **ฐานความรู้ภายนอก** - ใช้แหล่งข้อมูลที่เชื่อถือได้ในการอ้างอิง หาใน Internet วิธีแก้ปัญหาที่พบ เพราะอาจจะมีคนอื่นเจอปัญหาเดียวกันแล้วแก้ไขไว้แล้ว

## 🚫 ข้อห้ามเด็ดขาด (Absolute Prohibitions)

### 1. ห้ามแก้โค้ดโดยไม่ถามก่อน
- ❌ **ห้ามแก้ไขทันที** - ต้องถามและแสดงแผนก่อนเสมอ
- ❌ **ห้ามใช้ Isolate** สำหรับ background tasks (ใช้ Timer + ObjectBox แทน)
- ❌ **ห้ามใช้ Compute** สำหรับ background tasks (ใช้ Timer + ObjectBox แทน)
- ✅ **ต้องทำ**: แสดงแผน → อธิบายผลกระทบ → รอการอนุมัติ
- ✅ **ต้องทำ**: ค้นหา best practices จาก Flutter/Dart docs ก่อนเสนอ

### 2. ห้ามแก้ไข Business Logic โดยพลการ
- ❌ **ห้ามเปลี่ยน** logic การคำนวณ (เว้นแต่ได้รับอนุญาต)
- ❌ **ห้ามเปลี่ยน** flow การทำงานหลัก (เว้นแต่ได้รับอนุญาต)
- ❌ **ห้ามลบ** features ที่มีอยู่
- ✅ **อนุญาต**: Optimize performance โดยไม่เปลี่ยน output
- ⭐ **บังคับทดสอบ**: output/behavior ต้องเหมือนเดิม 100%

### 3. ห้ามสร้างไฟล์เอกสาร
- ❌ **ห้ามสร้าง** ไฟล์ `.md` ใหม่ (เว้นแต่ได้รับอนุญาต) อนุญาติให้สร้าง markdown (.md) ใน folder userguide และให้ เพิ่ม แก้ไข file .md ใน folder นั้นได้ ตาม source code ที่เปลี่ยนไป
- ❌ **ห้ามสร้าง** documentation files โดยไม่ได้ขอ
- ✅ **อนุญาต**: อัพเดท README.md ที่มีอยู่ (เมื่อได้รับคำสั่ง)
- ✅ **แนะนำ**: ใช้ comments ในโค้ดแทนการสร้างไฟล์

## ✅ หน้าที่หลัก (Primary Responsibilities)

### 1. Performance Optimization
**เป้าหมาย: ปรับปรุงความเร็วโดยไม่กระทบการทำงานเดิม**

#### Code Optimization Priorities:
1. **Async Operations** (สำคัญที่สุด)
   - แปลง sync operations เป็น async
   - ใช้ `Future.wait()` สำหรับ parallel processing
   - หลีกเลี่ยง blocking operations
   - ใช้ AppLogger ใน debug mode เพื่อบันทึกเหตุการณ์ทำงาน เพื่อช่วยวิเคราะห์ performance และหาจุดบกพร่อง ตามความเหมาะสม

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
    AppLogger('[Performance] expensiveOperation took ${stopwatch?.elapsedMilliseconds}ms');
  }
}

// ❌ BAD - Logs in production
Future<void> expensiveOperation() async {
  final stopwatch = Stopwatch()..start();
  await processData();
  AppLogger('Took ${stopwatch.elapsedMilliseconds}ms'); // ทำงานใน production!
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

#### Smoothness Rules (เพื่อ 60 FPS):
1. **ไม่มี UI Blocking**
   - ❌ ห้ามใช้ `Future.delayed()` เกิน 100ms ใน main thread
   - ❌ ห้ามใช้ sync file I/O (ใช้ async แทน)
   - ❌ ห้าม heavy computation ใน `build()`

2. **setState() Management**
   - ใช้ `setState()` เฉพาะส่วนที่จำเป็น
   - แยก state ออกเป็น smaller widgets
   - ใช้ `ValueNotifier` สำหรับ local state

3. **Animation Best Practices**
   - ใช้ `AnimationController` และ dispose ถูกต้อง
   - หลีกเลี่ยง animation loops ที่ไม่จำเป็น
   - ใช้ `AnimatedBuilder` เพื่อลด rebuilds

4. **List Performance**
   - ใช้ `ListView.builder` สำหรับ long lists
   - ใช้ `const` ใน list items ทุกที่ที่เป็นไปได้
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
**เป้าหมาย: ใช้ Best Practices จากแหล่งที่เชื่อถือได้**

#### ต้องอ้างอิงจาก:
- **Flutter Official Documentation** - [flutter.dev](https://flutter.dev/docs)
- **Dart Language Specification** - [dart.dev](https://dart.dev/guides)
- **Material Design Guidelines** - Material 3
- **Performance Best Practices** - Flutter performance profiling
- **Community-proven patterns** - pub.dev packages

### 5. Code Quality Standards

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

## 🔄 Workflow (ขั้นตอนก่อนแก้ไขโค้ด)

### ⚠️ ก่อนแก้ไขโค้ดทุกครั้ง ต้องทำตามลำดับ:

#### 1️⃣ ASK FIRST (ถามก่อนเสมอ)
- แสดง**แผนการแก้ไข**ที่ชัดเจน
- อธิบาย**ผลกระทบ**ที่อาจเกิดขึ้น
- **รอการอนุมัติ**ก่อนแก้ไข

#### 2️⃣ RESEARCH FIRST (ค้นคว้าก่อน)
- ค้นหา **best practices** จาก Flutter/Dart docs
- ตรวจสอบ **Material Design guidelines**
- ดู **performance benchmarks** ที่เกี่ยวข้อง
- หา **community solutions** จาก pub.dev

#### 3️⃣ ANALYZE WEAKNESSES (วิเคราะห์จุดอ่อน)
- ระบุ **performance bottlenecks**
- หา **code smells** และ anti-patterns
- ตรวจสอบ **security issues**
- แนะนำ**การปรับปรุง**พร้อมเหตุผล

#### 4️⃣ EXPLAIN IMPACT (อธิบายผลกระทบ)
- **Performance gain** ที่คาดหวัง (%)
- **Risks** ที่อาจเกิดขึ้น
- **Alternative approaches** (ถ้ามี)

#### 5️⃣ SHOW BEFORE/AFTER (แสดงก่อน-หลัง)
- แสดง**โค้ดเดิม** vs **โค้ดใหม่**
- อธิบาย**ความแตกต่าง**
- Highlight **breaking changes** (ถ้ามี)

#### 6️⃣ ADD PERFORMANCE LOGGING (เพิ่มการวัดผล)
- เพิ่ม **performance measurements** ใน debug mode
- วัด**เวลาการทำงาน**ของ functions ที่แก้ไข
- ใช้ `Stopwatch` หรือ `Timeline` API
- Log ต้องอยู่ใน `if (kDebugMode) { ... }` **เท่านั้น**

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

## ✅ Code Review Checklist

### ตรวจสอบก่อนเสนอการแก้ไขทุกครั้ง:

- [ ] ✅ **ไม่กระทบ business logic** - output/behavior เหมือนเดิม 100%
- [ ] ✅ **เพิ่มความเร็ว/ลื่นไหล** - วัดผลได้จริง
- [ ] ✅ **ใช้ async ถูกต้อง** - ไม่ block UI thread
- [ ] ✅ **มี error handling** - try-catch ครบถ้วน
- [ ] ✅ **Dispose resources** - controllers, streams, listeners
- [ ] ✅ **ใช้ const** ทุกที่ที่เป็นไปได้
- [ ] ✅ **ไม่มี memory leak** - ไม่มี dangling references
- [ ] ✅ **Test แล้วทำงานเหมือนเดิม** - ไม่มี regression

## 🚨 Red Flags (ห้ามทำสิ่งเหล่านี้)

### ⛔ Anti-Patterns ที่ห้ามใช้:

```dart
// ❌ 1. Sync file operations - Block UI thread
File(path).readAsStringSync();
// ✅ ใช้: await File(path).readAsString();

// ❌ 2. Blocking delays - Waste time
await Future.delayed(Duration(seconds: 3));
// ✅ ใช้: await actualAsyncOperation();

// ❌ 3. setState ใน addListener - Rebuild ทุก frame
animation.addListener(() {
  setState(() {});  // Rebuild ทั้งหน้าทุก frame!
});
// ✅ ใช้: AnimatedBuilder(animation: animation, ...)

// ❌ 4. Empty setState - Pointless rebuild
setState(() {});
// ✅ ใช้: setState(() { variable = newValue; })

// ❌ 5. No mounted check after async - Crash risk
await someAsyncOperation();
setState(() {});  // อาจจะ crash!
// ✅ ใช้: if (mounted) { setState(() {}); }

// ❌ 6. Nested loops with expensive operations - O(n*m)
for (var i in list1) {
  for (var j in list2) {
    jsonDecode(i.data);  // O(n*m) + expensive!
  }
}
// ✅ ใช้: Precalculate, cache, หรือใช้ Map lookup
```

## 📚 Learning Resources References

### เมื่อเสนอ optimization ให้อ้างอิงจาก:

#### Official Documentation:
- 📘 [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- 📗 [Dart Async Programming Guide](https://dart.dev/codelabs/async-await)
- 📙 [Material Design Guidelines](https://m3.material.io/)

#### Performance & Optimization:
- ⚡ Widget Build Optimization Patterns
- 🧠 Memory Management in Flutter
- 🎬 Flutter Animation Best Practices
- 📊 Flutter DevTools Performance Profiling

#### Code Quality:
- ✨ Effective Dart Style Guide
- 🏗️ Flutter Architecture Patterns
- 🔒 Flutter Security Best Practices

## 🔧 Debug Mode Best Practices

### Performance Logging & Debug Output:

```dart
// ✅ แนะนำ - Informative logs with context
if (kDebugMode) {
  AppLogger('[Component] 🚀 Action: details');
}

// ✅ แนะนำ - Performance measurement
if (kDebugMode) {
  final stopwatch = Stopwatch()..start();
  await expensiveOperation();
  stopwatch.stop();
  AppLogger('[Perf] Operation took ${stopwatch.elapsedMilliseconds}ms');
}

// ❌ ห้าม - Production prints
print('Debug info');  // จะทำงานใน production ด้วย!

// ❌ ห้าม - Performance code in production
final stopwatch = Stopwatch()..start();  // Waste resources!
```

### Debug-Only Code Guidelines:
- ✅ ใช้ `if (kDebugMode) { ... }` สำหรับ debug code ทั้งหมด
- ✅ Log performance metrics เฉพาะ debug builds
- ✅ Detailed error messages ใน debug, generic ใน production
- ❌ ห้าม `print()` โดยตรง - ต้องมี `kDebugMode` check เสมอ

## 📐 Measurement Guidelines

### เมื่อ optimize ให้วัดผลเสมอ:

#### Performance Metrics:
1. ⏱️ **Execution Time**: Before/After execution time (milliseconds)
2. 🧠 **Memory Usage**: Heap size, allocations, leaks
3. 🎬 **Frame Rate**: Target 60 FPS (16.67ms per frame)
4. 🚀 **Cold Start Time**: App launch to first frame
5. ⚡ **Hot Reload Time**: Code change to UI update

#### Measurement Tools:
- 📊 **Flutter DevTools**: Performance, Memory, CPU profiler
- ⏱️ **Stopwatch**: `Stopwatch()..start()` for timing
- 📈 **Timeline API**: `Timeline.startSync()` / `Timeline.finishSync()`
- 🔍 **Observatory**: Detailed VM metrics

#### Target Benchmarks:
- ✅ **60 FPS**: No frames over 16.67ms
- ✅ **Memory**: No leaks, reasonable heap size
- ✅ **Build time**: Widget build < 1ms for simple widgets
- ✅ **Response time**: User actions < 100ms feedback

## 🎯 Success Criteria

### การเปลี่ยนแปลงโค้ดถือว่าสำเร็จเมื่อ:

#### 🔧 Technical Requirements:
1. ✅ **Correctness**: ทำงานได้เหมือนเดิม 100% - no regression
2. ✅ **Performance**: เร็วขึ้นอย่างน้อย 10% - measured improvement
3. ✅ **Smoothness**: UI ลื่นไหลขึ้น (60 FPS sustained)
4. ✅ **Stability**: ไม่มี memory leak - proper resource disposal
5. ✅ **Maintainability**: Code อ่านง่ายขึ้น - clear structure

#### 🎨 UX/UI Requirements:
6. ✅ **Visual Design**: UI ดูสวยงามขึ้น - follows Material Design
7. ✅ **Responsiveness**: UX ดีขึ้น (fast feedback, accessible)
8. ✅ **Consistency**: ใช้ theme และ spacing อย่างสม่ำเสมอ

#### 📊 Validation Methods:
- ✅ **Benchmarking**: วัดเวลาก่อน/หลัง ด้วย `Stopwatch`
- ✅ **Testing**: ทดสอบ use cases ทั้งหมด
- ✅ **Memory Profiling**: ตรวจสอบ memory usage
- ✅ **Frame Rate**: วัดด้วย Flutter DevTools Performance

---

## 🎓 Core Philosophy

**สรุปหลักการทำงาน:**

> **คิดก่อนแก้** → ค้นคว้าก่อนทำ → ถามก่อนเปลี่ยน → วัดผลหลังเสร็จ 🎯

**4 ขั้นตอนสู่ความสำเร็จ:**
1. 🧠 **THINK**: วิเคราะห์ปัญหาและผลกระทบ
2. 📚 **RESEARCH**: หา best practices และ proven solutions
3. 🤝 **ASK**: ขออนุญาติและรับ feedback ก่อนเริ่มงาน
4. 📊 **MEASURE**: วัดผลและยืนยันว่าดีขึ้นจริง

**Remember**: ทุก optimization ต้องวัดผลได้ ทุกการเปลี่ยนแปลงต้องไม่ทำลาย business logic 🛡️
