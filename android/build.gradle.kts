allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Plugins compile against at least the app's Android SDK: the key store
// plugin (biometric_storage 5) asks for 31, while the androidx.biometric it
// uses needs 33 or later. Compiling against a newer SDK changes nothing on
// the devices it runs on (minSdk and targetSdk decide that).
// (finalizeDsl: after the plugin's own settings, before they're used; later
// than that, Gradle refuses the change.)
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { android ->
                if ((android.compileSdk ?: 0) < 36) android.compileSdk = 36
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
