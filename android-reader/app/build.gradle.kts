plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "ao.faztudo.iptv"
    compileSdk = 35
    defaultConfig {
        applicationId = "ao.faztudo.iptv"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}
dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("androidx.media3:media3-exoplayer:1.5.1")
    implementation("androidx.media3:media3-ui:1.5.1")
}
