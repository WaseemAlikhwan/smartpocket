allprojects {
    repositories {
        google()
        mavenCentral()
        // Fallback mirrors when default hosts fail to resolve (DNS / corporate network).
        maven(url = uri("https://maven.aliyun.com/repository/public"))
        maven(url = uri("https://maven.aliyun.com/repository/google"))
        maven(url = uri("https://plugins.gradle.org/m2/"))
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
