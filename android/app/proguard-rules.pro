# Google Tink (used by Amplify/Cognito secure storage) references compile-only annotations.
# See: https://github.com/mogol/flutter_secure_storage/issues/748
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# Amplify / AWS
-keep class com.amazonaws.** { *; }
-keep class amplify.** { *; }
