# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core Library
-keep class com.google.android.play.core.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# Keep model classes
-keep class com.example.road_helperr.models.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# HTTP
-keep class com.example.road_helperr.services.** { *; }

# Firebase (if used)
-keep class com.google.firebase.** { *; }

# General Android rules
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
