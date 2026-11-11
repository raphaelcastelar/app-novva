import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // Aplicado abaixo somente quando android/app/google-services.json existir.
    id("com.google.gms.google-services") apply false
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key de produção. O arquivo android/key.properties e a keystore
// nunca devem ser versionados (ver docs/android_play_store_handoff.md, etapa 8).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val googleServicesFile = file("google-services.json")
val hasGoogleServices = googleServicesFile.exists()
if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        "android/app/google-services.json não encontrado: notificações push ficarão " +
            "desativadas neste build. Builds release exigem esse arquivo.",
    )
}

val isReleaseBuildRequested =
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (isReleaseBuildRequested) {
    if (!hasReleaseSigning) {
        throw GradleException(
            "android/key.properties não encontrado. Builds release do Novva precisam da " +
                "upload key de produção e nunca são assinados com a chave de debug.",
        )
    }
    if (!hasGoogleServices) {
        throw GradleException(
            "android/app/google-services.json não encontrado. Baixe o arquivo do app " +
                "Android br.com.novva.app no Firebase antes de gerar a release.",
        )
    }
}

android {
    namespace = "br.com.novva.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Igual ao Bundle ID do iOS. Não pode mudar depois do primeiro upload na Google Play.
        applicationId = "br.com.novva.app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Tema AppCompat exigido pelo diálogo biométrico do local_auth.
    implementation("androidx.appcompat:appcompat:1.7.1")
}

flutter {
    source = "../.."
}
