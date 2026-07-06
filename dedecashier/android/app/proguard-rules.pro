-keep class com.smlsoft.dedecashier.DisplayJson { *; }
-keep class android.view.Display { *; }
-keep class android.hardware.display.DisplayManager { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep MainActivity and its methods
-keep class com.smlsoft.dedecashier.MainActivity { *; }
-keep class com.smlsoft.dedecashier.MainActivity$* { *; }

# Keep method channel handlers
-keepclassmembers class com.smlsoft.dedecashier.MainActivity {
    public void onMethodCall(io.flutter.plugin.common.MethodCall, io.flutter.plugin.common.MethodChannel$Result);
}

# Keep DisplayJson serialization
-keepclassmembers class com.smlsoft.dedecashier.DisplayJson {
    *;
}

# Keep Gson annotations
-keepattributes *Annotation*
-keepattributes Signature
-keep class com.google.gson.** { *; }
# Keep all fields that have @SerializedName
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepclassmembers class com.smlsoft.dedecashier.DisplayJson {
    <fields>;
}
-keep class com.smlsoft.bcpos.DisplayJson { *; }
-keepclassmembers class com.smlsoft.bcpos.DisplayJson { <fields>; }

-keep class com.smlsoft.marinepos.DisplayJson { *; }
-keepclassmembers class com.smlsoft.marinepos.DisplayJson { <fields>; }




# Keep display-related classes
-keep class android.view.Display$* { *; }
-keep class android.hardware.display.DisplayManager$* { *; }

# Flutter entry points - prevent tree-shaking
-keep class io.flutter.app.FlutterMain { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }

# Keep Flutter framework classes
-keep class io.flutter.** { *; }

# Keep Dart VM entry points
-keep class ** {
    @kotlin.jvm.JvmStatic <methods>;
}

# Keep all methods annotated with @pragma('vm:entry-point')
-keep @interface kotlin.jvm.JvmStatic
-keep class ** {
    @kotlin.jvm.JvmStatic <methods>;
}

# Additional Flutter-related rules for release builds
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.util.**
-dontwarn io.flutter.view.**
-dontwarn io.flutter.**