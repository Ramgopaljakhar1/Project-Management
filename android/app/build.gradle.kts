plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.app.projectmanagement"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

//    lintOptions {
//        checkReleaseBuilds false
//        abortOnError false
//    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.app.projectmanagement"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 10
        versionName = "1.8"
    }
    signingConfigs {
        create("release") {
            storeFile = file("projectmanagement-keystore.jks")
            storePassword = "PM@123"
            keyAlias = "projectmanagement"
            keyPassword = "PM@123"
        }
    }

    buildTypes {
        getByName("release") {
//            isMinifyEnabled = true
//            isShrinkResources = true
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    file("proguard-rules.pro")
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

}

flutter {
    source = "../.."
}
