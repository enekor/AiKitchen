import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.N3k0chan.aikitchen"
    // 37 no es una versión estable descargable del SDK todavía (de ahí el
    // "suppressUnsupportedCompileSdk" que arrastraba gradle.properties);
    // 36 es la última estable y ya cumple el mínimo pedido.
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.N3k0chan.aikitchen"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Fijado a 36 en lugar del valor por defecto de Flutter (más bajo):
        // requisito del proyecto, no una elección de Flutter.
        minSdk = 36
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // `keystore.properties` no está en el repositorio (está en .gitignore, es
    // un secreto local de cada máquina de publicación). Antes se leía sin
    // comprobar que existiera, así que faltaba en cualquier equipo nuevo
    // -incluido este WSL- y ni siquiera se podía compilar en modo depuración.
    val keystorePropertiesFile = rootProject.file("keystore.properties")
    val hasReleaseKeystore = keystorePropertiesFile.exists()

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true // Enable code shrinking, obfuscation, and optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Sin la clave de publicación, el release se firma con la de
            // depuración: no sirve para subir a la Play Store, pero permite
            // compilar y probar la variante release en cualquier máquina.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "ATENCIÓN: falta android/keystore.properties. " +
                        "El build de release se firma con la clave de depuración " +
                        "y NO es válido para publicar."
                )
                signingConfigs.getByName("debug")
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    jvmToolchain(17)
}
