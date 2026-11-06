plugins { id("com.android.application") }

android {
    namespace = "ao.faztudo.iptv"
    compileSdk = 35
    defaultConfig {
        applicationId = "ao.faztudo.iptv"
        minSdk = 27
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.media3:media3-exoplayer:1.5.1")
    implementation("androidx.media3:media3-ui:1.5.1")
}
