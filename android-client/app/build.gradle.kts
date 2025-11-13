plugins {
    alias(libs.plugins.android.application)
    id("com.diffplug.spotless") version "8.0.0"
}

android {
    namespace = "com.example.android_client"
    compileSdk {
        version = release(36)
    }

    defaultConfig {
        applicationId = "com.example.android_client"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    lint {
        abortOnError = true
        warningsAsErrors = true
        checkAllWarnings = true

        disable += "UnusedResources"
    }

    spotless {
        java {
            target("src/**/*.java")
            // Check available versions here:
            // https://github.com/google/google-java-format
            googleJavaFormat("1.32.0").aosp()
            removeUnusedImports()
            trimTrailingWhitespace()
            endWithNewline()
        }
    }
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.activity)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)
}