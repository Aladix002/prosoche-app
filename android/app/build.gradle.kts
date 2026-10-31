import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release podpis (docs/06 B.3, D.3). Zdroj v poradi:
//  1. android/key.properties (storeFile, storePassword, keyAlias, keyPassword),
//     CI ho vytvori zo secrets a po builde zmaze,
//  2. env PROSOCHE_UPLOAD_STORE_FILE, PROSOCHE_UPLOAD_STORE_PASSWORD,
//     PROSOCHE_UPLOAD_KEY_ALIAS, PROSOCHE_UPLOAD_KEY_PASSWORD.
// Ak nic z toho nie je: PROSOCHE_REQUIRE_RELEASE_SIGNING=true -> build zlyha
// (release workflow), inak release sa podpise debug klucom s warningom
// (lokalny build, PR build so PROSOCHE_CI_UNSIGNED=true). Taky AAB Play odmietne.
// Kluce ani key.properties sa nikdy necommituju (.gitignore).
val uploadSigning: Map<String, String>? = run {
    val keyPropsFile = rootProject.file("key.properties")
    val values = if (keyPropsFile.isFile) {
        val props = Properties()
        keyPropsFile.inputStream().use { props.load(it) }
        mapOf(
            "storeFile" to props.getProperty("storeFile"),
            "storePassword" to props.getProperty("storePassword"),
            "keyAlias" to props.getProperty("keyAlias"),
            "keyPassword" to props.getProperty("keyPassword"),
        )
    } else {
        mapOf(
            "storeFile" to System.getenv("PROSOCHE_UPLOAD_STORE_FILE"),
            "storePassword" to System.getenv("PROSOCHE_UPLOAD_STORE_PASSWORD"),
            "keyAlias" to System.getenv("PROSOCHE_UPLOAD_KEY_ALIAS"),
            "keyPassword" to System.getenv("PROSOCHE_UPLOAD_KEY_PASSWORD"),
        )
    }
    val missing = values.filterValues { it.isNullOrBlank() }.keys
    when {
        missing.isEmpty() -> values.mapValues { it.value!! }
        keyPropsFile.isFile -> throw GradleException(
            "android/key.properties nema: ${missing.joinToString()}",
        )
        else -> null
    }
}
if (uploadSigning == null) {
    // Kontrola len ked sa realne stavia release (debug/profile buildy ticho).
    gradle.taskGraph.whenReady {
        val buildsRelease = allTasks.any {
            it.project == project && it.name.endsWith("Release") &&
                (it.name.startsWith("assemble") || it.name.startsWith("bundle"))
        }
        if (!buildsRelease) return@whenReady
        if (System.getenv("PROSOCHE_REQUIRE_RELEASE_SIGNING") == "true") {
            throw GradleException(
                "PROSOCHE_REQUIRE_RELEASE_SIGNING=true, ale chyba android/key.properties " +
                    "aj PROSOCHE_UPLOAD_* env (docs/06 B.3).",
            )
        }
        val msg = "Release build je podpisany DEBUG klucom (chyba android/key.properties " +
            "aj PROSOCHE_UPLOAD_* env). Len na lokalne testovanie, Google Play ho odmietne."
        if (System.getenv("PROSOCHE_CI_UNSIGNED") == "true") {
            logger.lifecycle("PROSOCHE_CI_UNSIGNED=true: $msg")
        } else {
            logger.warn("\nWARNING: $msg\n")
        }
    }
}

android {
    namespace = "app.prosoche"
    // Google Play od 31. 8. 2026 vyzaduje targetSdk 36 (docs/08 cast A).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications vyzaduje core library desugaring.
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "app.prosoche"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Q-01: Patrol E2E (patrol_test/, tool/e2e.sh). Data sa medzi
        // testami nemazu (restart scenar), cisti ich harness testu.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    }

    // Q-01: kazdy Patrol test v novom procese (restart appky v scenari 6).
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    // Dimenzie env (dev, prod) x edition (lite, full) -> devLite, devFull,
    // prodLite, prodFull. `lite` = produkcia B (Ramadan edition) bez brany,
    // `full` pridava zdrojovy set src/full/ (blocker, FGS, usage access,
    // overlay). PLAN_VYVOJA S-01b, docs/10 6.1. Rovnake applicationId.
    flavorDimensions += listOf("env", "edition")
    productFlavors {
        create("lite") {
            dimension = "edition"
        }
        create("full") {
            dimension = "edition"
            versionNameSuffix = "-full"
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Prosoche Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Prosoche")
        }
    }

    signingConfigs {
        if (uploadSigning != null) {
            create("release") {
                storeFile = file(uploadSigning.getValue("storeFile"))
                storePassword = uploadSigning.getValue("storePassword")
                keyAlias = uploadSigning.getValue("keyAlias")
                keyPassword = uploadSigning.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // R8 + resource shrinking, pravidla v proguard-rules.pro (docs/06 B.5).
            // Dart kod sa obfuskuje zvlast: --obfuscate --split-debug-info.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            // native-debug-symbols.zip pre Play vitals (docs/06 D.3).
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // B-02: Pigeon suspend API a Dispatchers.Main v src/full (BlockerHostApiImpl,
    // GateActivity). Doteraz prichadzalo len tranzitivne cez pluginy.
    "fullImplementation"("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    // B-01: JUnit/Robolectric testy nativneho blockeru (src/testFull).
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16.1")
    // Q-01: Patrol E2E cez Android Test Orchestrator.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
