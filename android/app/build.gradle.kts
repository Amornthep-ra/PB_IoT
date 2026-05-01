import org.gradle.api.GradleException
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.princebot.iot"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.princebot.iot"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.register("validateReleaseSigning") {
    doLast {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "Missing android/key.properties. Create it from android/key.properties.example before building release."
            )
        }

        val missingProperties = listOf(
            "storePassword",
            "keyPassword",
            "keyAlias",
            "storeFile",
        ).filter { keystoreProperties.getProperty(it).isNullOrBlank() }

        if (missingProperties.isNotEmpty()) {
            throw GradleException(
                "Missing release signing properties in android/key.properties: ${missingProperties.joinToString(", ")}"
            )
        }

        val releaseStoreFile = file(keystoreProperties.getProperty("storeFile"))
        if (!releaseStoreFile.exists()) {
            throw GradleException(
                "Release keystore not found: ${releaseStoreFile.path}"
            )
        }
    }
}

tasks.matching {
    it.name in listOf(
        "assembleRelease",
        "bundleRelease",
        "packageRelease",
        "validateSigningRelease",
    )
}.configureEach {
    dependsOn("validateReleaseSigning")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
