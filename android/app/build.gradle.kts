import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val releaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

fun releaseSigningValue(key: String) = keystoreProperties.getProperty(key).orEmpty()

android {
    namespace = "me.ansarihamedani.sweatline"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "me.ansarihamedani.sweatline"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = releaseSigningValue("keyAlias")
                keyPassword = releaseSigningValue("keyPassword")
                storePassword = releaseSigningValue("storePassword")
                releaseSigningValue("storeFile").takeIf { it.isNotBlank() }?.let {
                    storeFile = file(it)
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

tasks.register("validateReleaseSigning") {
    doLast {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "Missing android/key.properties. Create it with storeFile, storePassword, keyAlias, and keyPassword before building a release."
            )
        }
        val missingKeys = releaseSigningKeys.filter { releaseSigningValue(it).isBlank() }
        if (missingKeys.isNotEmpty()) {
            throw GradleException(
                "android/key.properties is missing required values: ${missingKeys.joinToString(", ")}."
            )
        }
        val configuredStoreFile = file(releaseSigningValue("storeFile"))
        if (!configuredStoreFile.exists()) {
            throw GradleException(
                "The release keystore file does not exist: ${configuredStoreFile.path}."
            )
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn("validateReleaseSigning")
}

tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach {
    dependsOn("validateReleaseSigning")
}
