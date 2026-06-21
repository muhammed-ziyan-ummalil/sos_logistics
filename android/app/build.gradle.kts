plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // com.google.gms.google-services is applied conditionally at the bottom of this
    // file — only when google-services.json exists — so the app still builds before
    // `flutterfire configure --project=sos-6b1be` has been run.
}

android {
    namespace = "com.sossss.logistics.sossss_logistics"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sossss.logistics"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps key for the AndroidManifest ${GOOGLE_MAPS_API_KEY} placeholder.
        // Set GOOGLE_MAPS_API_KEY in android/gradle.properties or ~/.gradle/gradle.properties.
        // Empty fallback keeps debug builds working before the real key is configured
        // (maps tiles will not render until a real key is provided).
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            (project.findProperty("GOOGLE_MAPS_API_KEY") as String?) ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Apply the Google Services plugin (FCM) only when its config file is present.
// Until `flutterfire configure --project=sos-6b1be` generates google-services.json,
// the plugin is skipped so the app builds; Firebase init in main.dart is guarded.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
