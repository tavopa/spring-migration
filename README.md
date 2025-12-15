# Spring Boot Migration Pipeline

Este repositorio contiene pipelines de GitHub Actions para automatizar la migración de proyectos Spring Boot a versiones más recientes de Java y Spring Boot.

## Características

- ✅ Clonado automático de múltiples repositorios desde una lista configurable
- ✅ Análisis de dependencias Maven (Java, Spring Boot y otras)
- ✅ Actualización automática de dependencias usando OpenRewrite
- ✅ Análisis de compatibilidad JDK con `jdeps` y `jdeprscan`
- ✅ Testing automático con matrix CI (unit, integration, contract, smoke tests)
- ✅ Creación automática de Pull Requests con label "requires QA"
- ✅ Soporte para Docker en los pipelines

## Estructura del Proyecto

```
.
├── .github/
│   └── workflows/
│       ├── spring-migration.yml    # Pipeline principal de migración
│       └── test-matrix.yml         # Workflow reutilizable para tests
├── conf/
│   └── repos.yaml                  # Lista de repositorios a migrar
├── scripts/
│   ├── apply-openrewrite.sh        # Script helper para OpenRewrite
│   └── analyze-jdk-compatibility.sh # Script helper para análisis JDK
└── README.md
```

## Configuración

### 1. Configurar Repositorios

Edita el archivo `conf/repos.yaml` para agregar los repositorios que deseas migrar:

```yaml
repositories:
  - owner: "tu-org"
    repo: "mi-spring-app"
    branch: "main"
  - owner: "tu-org"
    repo: "otra-app"
    branch: "develop"

migration:
  target_java_version: "21"
  target_spring_boot_version: "3.2.0"
  openrewrite_recipes:
    - "org.openrewrite.java.migrate.UpgradeToJava21"
    - "org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2"
    - "org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta"
```

### 2. Permisos de GitHub Token

El pipeline requiere un token de GitHub con permisos para:
- Leer repositorios
- Crear branches
- Crear Pull Requests
- Agregar labels

El `GITHUB_TOKEN` proporcionado por GitHub Actions tiene estos permisos por defecto, pero asegúrate de que el workflow tenga acceso a los repositorios objetivo.

## Uso

### Ejecución Manual

1. Ve a la pestaña "Actions" en GitHub
2. Selecciona "Spring Boot Migration Pipeline"
3. Haz clic en "Run workflow"
4. Opcionalmente configura:
   - **repos_file**: Ruta al archivo YAML de repositorios (default: `conf/repos.yaml`)
   - **dry_run**: Modo de prueba sin crear PRs (default: `false`)

### Ejecución Programada

El pipeline está configurado para ejecutarse automáticamente cada lunes a las 2 AM UTC. Puedes modificar el schedule en `.github/workflows/spring-migration.yml`.

## Proceso de Migración

El pipeline ejecuta los siguientes pasos para cada repositorio:

1. **Clonado**: Clona el repositorio desde la lista configurada
2. **Análisis de Dependencias**: Extrae versiones actuales de Java y Spring Boot
3. **OpenRewrite**: Actualiza dependencias y código según las recetas configuradas
4. **Compilación**: Verifica que el proyecto compile correctamente
5. **Análisis JDK**:
   - `jdeps`: Detecta uso de APIs internas de JDK
   - `jdeprscan`: Detecta uso de APIs deprecadas
6. **Tests**: Ejecuta tests en matrix (unit, integration, contract, smoke)
7. **Creación de PR**: Crea un Pull Request con los cambios y label "requires QA"

## Tests Matrix

El pipeline ejecuta los siguientes tipos de tests:

- **Unit Tests**: Tests unitarios (`**/*Test`)
- **Integration Tests**: Tests de integración (`**/*IT`)
- **Contract Tests**: Tests de contrato (Spring Cloud Contract)
- **Smoke Tests**: Tests básicos en contenedor Docker

Los tests se ejecutan en múltiples versiones de Java (17 y 21) para verificar compatibilidad.

## Pull Requests Automáticos

Cada migración genera un Pull Request con:

- Título descriptivo con versiones objetivo
- Descripción detallada de cambios
- Información de análisis (jdeps, jdeprscan)
- Label **"requires QA"** para revisión obligatoria
- Labels adicionales: `automated`, `migration`

## Troubleshooting

### El pipeline falla al clonar repositorios

- Verifica que el `GITHUB_TOKEN` tenga acceso a los repositorios
- Asegúrate de que los nombres de owner/repo sean correctos en `repos.yaml`

### OpenRewrite no aplica cambios

- Verifica que el proyecto tenga un `pom.xml` válido
- Revisa los logs del paso "Update dependencies with OpenRewrite"
- Algunos proyectos pueden requerir configuración manual adicional

### Tests fallan después de la migración

- Revisa los logs de tests en los artifacts
- Algunos tests pueden requerir actualización manual
- Verifica compatibilidad de dependencias específicas

### jdeps/jdeprscan reportan problemas

- Revisa los reports generados en los logs
- Algunos problemas pueden requerir cambios manuales en el código
- Considera usar APIs alternativas recomendadas por los tools

## Personalización

### Agregar Recetas de OpenRewrite

Edita `conf/repos.yaml` y agrega más recetas en `openrewrite_recipes`:

```yaml
openrewrite_recipes:
  - "org.openrewrite.java.migrate.lang.UseTextBlocks"
  - "org.openrewrite.java.migrate.lang.UseSwitchExpression"
```

### Modificar Versiones Objetivo

Actualiza `target_java_version` y `target_spring_boot_version` en `conf/repos.yaml`.

### Agregar Más Tipos de Tests

Modifica `.github/workflows/test-matrix.yml` para agregar más tipos de tests o configuraciones.

## Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Crea un issue para discutir cambios mayores
2. Haz fork del repositorio
3. Crea una branch para tu feature
4. Envía un Pull Request

## Licencia

[Especificar licencia si es necesario]

