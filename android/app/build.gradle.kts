plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.Taskio"
    compileSdk = 35 // Можно заменить на flutter.compileSdkVersion, если используете переменные из Flutter

    ndkVersion = "29.0.13599879" // Новейшая стабильная версия, которую вы используете

    defaultConfig {
        applicationId = "com.example.Taskio"
        minSdk = 23 // Обязательно не ниже 23, так требует firebase-auth
        targetSdk = 35 // Соответствует compileSdk
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // Пока используем debug ключ
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Для поддержки Java 8+ API (desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
