# ML Kit loads its translate/common components via reflection (ServiceLoader-style
# discovery in MlKitComponentDiscoveryService). R8 doesn't see those call sites, so
# without these keep rules it strips the no-arg constructors and registration fails
# at runtime with MissingPluginException on the google_mlkit_on_device_translator channel.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_translate.** { *; }
-dontwarn com.google.mlkit.**
