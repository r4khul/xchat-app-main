# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
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

-optimizationpasses 5

-dontusemixedcaseclassnames

-dontskipnonpubliclibraryclasses

-verbose
-ignorewarnings

-dontoptimize

-dontpreverify


-keepattributes *Annotation*


 -keep public class com.oxchat.nostr.R$*{
    public static final int *;
 }


-dontwarn org.apache.commons.codec_a.**
-keep class org.apache.commons.codec_a.**{*;}
-dontwarn com.eva.epc.common.**
-keep class com.eva.epc.common.**{*;}
-dontwarn com.alibaba.fastjson
-keep class com.alibaba.fastjson.**{*;}
-dontwarn com.google.**
-keep class com.google.**{*;}
-dontwarn org.apache.http.**
-keep class org.apache.http.**{*;}
-dontwarn org.apache.http.entity.mime.**
-keep class org.apache.http.entity.mime.**{*;}
-dontwarn net.openmob.mobileimsdk.android.**
-keep class net.openmob.mobileimsdk.android.**{*;}
-dontwarn net.openmob.mobileimsdk.server.protocal.**
-keep class net.openmob.mobileimsdk.server.protocal.**{*;}
-dontwarn okhttp3.**
-keep class okhttp3.**{*;}
-dontwarn okio.**
-keep class okio.**{*;}
-dontwarn com.paypal.android.sdk.**
-keep class com.paypal.android.sdk.**{*;}
-dontwarn io.card.payment.**
-keep class io.card.payment.**{*;}
-dontwarn com.hp.hpl.sparta.**
-keep class com.hp.hpl.sparta.**{*;}
-dontwarn net.sourceforge.pinyin4j.**
-keep class net.sourceforge.pinyin4j.**{*;}
-dontwarn net.x52im.rainbowav.sdk.**
-keep class net.x52im.rainbowav.sdk.**{*;}
-dontwarn com.vc.**
-keep class com.vc.**{*;}

-keep class com.luck.picture.lib.** { *; }
# use Camerax
-keep class com.luck.lib.camerax.** { *; }
#use uCrop
-dontwarn com.yalantis.ucrop**
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

-dontwarn com.geetest.captcha.**
-keep class com.geetest.captcha.**{*;}

# google.zxing
-dontwarn com.google.zxing.**
-keep class com.google.zxing.**{*;}

-keepclasseswithmembernames class * { native <methods>; }
-keep class com.android.internal.telephony.** {*;}

#sqflite_sqlcipher
-keep class net.sqlcipher.** { *; }
#secp256k1
-keep class fr.acinq.secp256k1.** { *; }

-keep class org.unifiedpush.** { *; }
-keep class io.flutter.** { *; }

# Google Play Billing Library
# Keep all classes from Google Play Billing Library to prevent obfuscation
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Flutter in_app_purchase plugin
# Keep all classes from in_app_purchase plugin
-keep class io.flutter.plugins.in_app_purchase.** { *; }
-keep class io.flutter.plugins.** { *; }

# Reflection support for in-app purchases
# Keep attributes needed for reflection calls used by billing library
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
