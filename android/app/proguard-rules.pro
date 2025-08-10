# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }
-keep class androidx.** { *; }
-keep class android.** { *; }

# Keep notification-related classes
-keepnames class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }

# Keep classes used by flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep classes with special names
-keepnames class com.dexterous.flutterlocalnotifications.**
-keepnames class androidx.work.**

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep notification channels and related classes
-keep class * extends android.app.NotificationChannel
-keep class * extends androidx.core.app.NotificationCompat$Builder

# Preserve annotations
-keepattributes *Annotation*

# Keep Flutter plugin registrant
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep reflection usage
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep generic types
-keepattributes Signature

# Additional rules for notification scheduling
-dontwarn com.dexterous.**
-dontwarn androidx.**
