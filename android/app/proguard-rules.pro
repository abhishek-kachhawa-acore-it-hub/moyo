# Keep Razorpay classes and suppress related warnings
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Google Pay (GPay) related classes and suppress warnings
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# Keep annotation attributes (required for runtime)
-keepattributes *Annotation*, RuntimeVisibleAnnotations

# Allow references to missing annotation interfaces to not break the build
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# If you want to create stubs for missing annotations (optional, but sometimes necessary)
# Uncomment below to define empty annotation interfaces so R8 doesn't fail
# -keep @interface proguard.annotation.Keep
# -keep @interface proguard.annotation.KeepClassMembers

# Parcelable and Serializable support
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-keepnames class * implements java.io.Serializable

# Prevent ProGuard from stripping interface information
-keep interface * extends *

# Kotlin-specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontnote kotlin.internal.**
-dontnote kotlin.reflect.jvm.**
-dontnote kotlin.coroutines.**

# Keep any methods/classes using custom proguard annotation for compatibility
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keepclassmembers class * {
    @proguard.annotation.KeepClassMembers *;
}

# Optional: Suppress verbose warnings in build output
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.Metadata
