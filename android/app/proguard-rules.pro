# Keep Geolocator plugin classes
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Keep Location plugin classes (if using the 'location' package)
-keep class com.lyokone.location.** { *; }
-dontwarn com.lyokone.location.**

# Keep Google Maps classes
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**