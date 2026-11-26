# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Minar App & Widgets
-keep class com.minar.app.** { *; }
-dontwarn com.minar.app.**

# Google Play Core Deferred Components
-dontwarn com.google.android.play.core.**
