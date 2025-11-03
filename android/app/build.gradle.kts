plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "de.asvgrossostheim.app"
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
        // Application ID für ASV Großostheim Vereinsapp
        applicationId = "de.asvgrossostheim.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release Signing Configuration
    // 1. Erstelle ein keystore file mit: keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    // 2. Erstelle android/key.properties mit folgendem Inhalt:
    //    storePassword=<password from previous step>
    //    keyPassword=<password from previous step>
    //    keyAlias=upload
    //    storeFile=<location of the key store file, e.g. /Users/<user>/upload-keystore.jks>
    // 3. Füge android/key.properties zur .gitignore hinzu (niemals committen!)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Verwende Release Signing Config wenn verfügbar, sonst Debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
