# Keep OkHttp3 classes needed by image_cropper
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep ucrop library
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }

# Keep HTTP client classes for API calls
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class javax.net.ssl.** { *; }

# Keep Retrofit
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn retrofit2.**

# Keep Chucker (HTTP interceptor)
-keep class com.chuckerteam.chucker.** { *; }
-dontwarn com.chuckerteam.chucker.**

# Keep SharedPreferences
-keep class android.content.SharedPreferences { *; }

# Keep your API models and services
-keep class com.example.haticare.** { *; }
-keep class io.flutter.** { *; }

# Keep JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
