// 1. Definimos y ASIGNAMOS la variable 'newBuildDir' correctamente
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()

// 2. Asignamos el valor al directorio de construcción del proyecto raíz
rootProject.layout.buildDirectory.value(newBuildDir)

// 3. Configuramos los subproyectos
subprojects {
    // Definimos el directorio de construcción para cada subproyecto basado en el nuevo directorio raíz
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Esto es común en Flutter para asegurar que el módulo app se evalúe para los plugins
    project.evaluationDependsOn(":app")
}

// 4. Tarea Clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}