allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // flutter_google_places_sdk_android 0.2.2 pins google_places_version=5.1.1 but its
    // Kotlin source uses the old Place API (place.address / place.latLng / place.name /
    // place.placeTypes) that was removed in Places SDK 4.0. Force back to 3.5.0 which
    // is the last release with the old API so the plugin compiles.
    configurations.all {
        resolutionStrategy.force("com.google.android.libraries.places:places:3.5.0")
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
