plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val werklyKeystore = rootProject.file("upload-keystore.jks")
val werklyStorePassword = System.getenv("WERKLY_UPLOAD_STORE_PASSWORD")
val werklyKeyPassword = System.getenv("WERKLY_UPLOAD_KEY_PASSWORD")
val werklyKeyAlias = System.getenv("WERKLY_UPLOAD_KEY_ALIAS") ?: "upload"
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isReleaseBuild &&
    (!werklyKeystore.exists() || werklyStorePassword.isNullOrBlank() || werklyKeyPassword.isNullOrBlank())
) {
    throw GradleException(
        "Signature Werkly absente. Lance tooling/build_android_release.ps1 depuis la racine du projet."
    )
}

android {
    namespace = "de.werkly.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "de.werkly.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = werklyKeystore
            storePassword = werklyStorePassword
            keyAlias = werklyKeyAlias
            keyPassword = werklyKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
