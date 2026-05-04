## Gson rules required for flutter_local_notifications scheduled notifications.
## Based on the plugin example and Gson's Android ProGuard guidance.

# Keep generic signatures used by Gson when deserialising scheduled payloads.
-keepattributes Signature

# Keep annotations so Gson can respect any serialized names/metadata.
-keepattributes *Annotation*

# Gson specific classes and adapters.
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep fields on model classes so reflection-based serialisation remains intact.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent stripping type information from anonymous/local type tokens.
-keep class * extends com.google.gson.reflect.TypeToken
