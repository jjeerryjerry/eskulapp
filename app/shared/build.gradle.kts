import org.jetbrains.kotlin.gradle.ExperimentalKotlinGradlePluginApi
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    // Target Android (konsumowany przez :app w przyszlosci; teraz weryfikuje common)
    androidTarget {
        @OptIn(ExperimentalKotlinGradlePluginApi::class)
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    // Targety iOS deklarujemy TYLKO na hoscie macOS (GitHub Actions macOS runner).
    // Wtedy tam buduje sie framework Shared do konsumpcji przez natywne SwiftUI.
    // Na Linuksie (serwer agenta) pomijamy je, zeby nie ciagnac Kotlin/Native i
    // moc zweryfikowac warstwe common+Android bez Maca.
    val isMacOs = System.getProperty("os.name").startsWith("Mac", ignoreCase = true)
    if (isMacOs) {
        val xcf = XCFramework("Shared")
        listOf(iosX64(), iosArm64(), iosSimulatorArm64()).forEach { t ->
            t.binaries.framework {
                baseName = "Shared"
                isStatic = true
                xcf.add(this)
            }
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
        }
        if (isMacOs) {
            iosMain.dependencies {
                implementation(libs.ktor.client.darwin)
            }
        }
    }
}

android {
    namespace = "pl.eskulapp.shared"
    compileSdk = 36
    defaultConfig {
        minSdk = 26
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
