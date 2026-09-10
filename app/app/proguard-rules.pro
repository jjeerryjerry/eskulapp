# ---- kotlinx.serialization (oficjalne reguly) ----
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault,InnerClasses
-dontnote kotlinx.serialization.**

# Keep `Companion` object fields of serializable classes.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}
# Keep `serializer()` on companion objects of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$Companion Companion;
}
-keepclassmembers class <2>$Companion {
    kotlinx.serialization.KSerializer serializer(...);
}
# Keep `INSTANCE.serializer()` of serializable objects.
-if @kotlinx.serialization.Serializable class ** {
    public static ** INSTANCE;
}
-keepclassmembers class <1> {
    public static <1> INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}

# ---- DTO aplikacji (parsowane z JSON API /bundle) ----
-keep class pl.eskulapp.mobile.data.model.** { *; }
-keepclassmembers class pl.eskulapp.mobile.data.model.** { *; }
-keep,includedescriptorclasses class pl.eskulapp.mobile.data.model.**$$serializer { *; }

# ---- Room ----
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao class * { *; }
-keep class pl.eskulapp.mobile.data.local.** { *; }
-dontwarn androidx.room.paging.**
