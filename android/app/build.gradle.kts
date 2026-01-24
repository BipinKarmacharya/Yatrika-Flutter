plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tour_guide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tour_guide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

// Copy produced APKs to a friendlier filename while keeping the originals.
// This avoids breaking tools that expect the default app-*.apk path.
tasks.register("copyApkWithCustomName") {
    doLast {
        val apkDirs = listOf(
            File(buildDir, "app/outputs/flutter-apk"),
            File(buildDir, "outputs/flutter-apk"),
            File(buildDir, "app/outputs/apk"),
            File(buildDir, "outputs/apk")
        )
        val prefix = "Yatrika-A smart trip planner-"
        apkDirs.forEach { dir ->
            if (dir.exists()) {
                dir.listFiles { f -> f.extension == "apk" }?.forEach { file ->
                    // Skip if it's already using our custom prefix
                    if (file.name.startsWith(prefix)) return@forEach
                    // Keep the original file, and also create a copy with a custom prefix
                    val customName = prefix + file.name
                    val dest = File(file.parentFile, customName)
                    try {
                        file.copyTo(dest, overwrite = true)
                        println("Copied ${file.name} -> ${dest.name}")
                    } catch (e: Exception) {
                        println("Failed to copy ${file.absolutePath} -> ${dest.absolutePath}: ${e.message}")
                    }
                }
            }
        }
    }
}

// Run the copy after common assemble tasks so the final APK keeps its default name
// and we also get a custom-named copy beside it.
listOf("assembleRelease", "assembleDebug").forEach { taskName ->
    tasks.matching { it.name == taskName }.configureEach {
        finalizedBy("copyApkWithCustomName")
    }
}
