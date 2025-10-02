# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Razorpay SDK
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepclassmembers class * extends com.razorpay.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core Library
-keep class com.google.android.play.core.** { *; }

# Razorpay Proguard rules (to prevent stripping of annotations)
-keep @interface proguard.annotation.Keep
-keep @interface proguard.annotation.KeepClassMembers
-keep class proguard.annotation.** { *; }
-keep class com.razorpay.** { *; }
-keep class * implements com.razorpay.Proguard$$Keep { *; }
-keep class * implements com.razorpay.Proguard$$KeepClassMembers { *; }
-keep class * implements com.razorpay.Proguard$$KeepClassAndMembers { *; }
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# Rules from missing_rules.txt to suppress warnings
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.PaymentsClient
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.Wallet
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.WalletUtils
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Keep common Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference
