#!/bin/bash
# Script para aplicar OpenRewrite a un proyecto Maven

set -e

POM_FILE="${1:-pom.xml}"
TARGET_JAVA="${2:-21}"
TARGET_SPRING_BOOT="${3:-3.2.0}"

if [ ! -f "$POM_FILE" ]; then
    echo "Error: $POM_FILE not found"
    exit 1
fi

echo "Applying OpenRewrite migrations..."
echo "Target Java: $TARGET_JAVA"
echo "Target Spring Boot: $TARGET_SPRING_BOOT"

# Backup original pom.xml
cp "$POM_FILE" "${POM_FILE}.backup"

# Check if OpenRewrite plugin already exists
if grep -q "rewrite-maven-plugin" "$POM_FILE"; then
    echo "OpenRewrite plugin already exists in pom.xml"
else
    echo "Adding OpenRewrite plugin to pom.xml"
    
    # Create plugin XML
    PLUGIN_XML=$(cat <<EOF
            <plugin>
              <groupId>org.openrewrite.maven</groupId>
              <artifactId>rewrite-maven-plugin</artifactId>
              <version>5.40.0</version>
              <configuration>
                <activeRecipes>
                  <recipe>org.openrewrite.java.migrate.UpgradeToJava${TARGET_JAVA}</recipe>
                  <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2</recipe>
                  <recipe>org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta</recipe>
                </activeRecipes>
              </configuration>
              <dependencies>
                <dependency>
                  <groupId>org.openrewrite.recipe</groupId>
                  <artifactId>rewrite-migrate-java</artifactId>
                  <version>20.0.0</version>
                </dependency>
                <dependency>
                  <groupId>org.openrewrite.recipe</groupId>
                  <artifactId>rewrite-spring</artifactId>
                  <version>5.7.0</version>
                </dependency>
              </dependencies>
            </plugin>
EOF
)
    
    # Insert plugin before </plugins> tag
    if grep -q "</plugins>" "$POM_FILE"; then
        # Use awk to insert before </plugins>
        awk -v plugin="$PLUGIN_XML" '/<\/plugins>/ {print plugin; print; next}1' "$POM_FILE" > "${POM_FILE}.tmp"
        mv "${POM_FILE}.tmp" "$POM_FILE"
    elif grep -q "</build>" "$POM_FILE"; then
        # Create plugins section if it doesn't exist
        awk -v plugin="$PLUGIN_XML" '/<\/build>/ {print "    <plugins>"; print plugin; print "    </plugins>"; print; next}1' "$POM_FILE" > "${POM_FILE}.tmp"
        mv "${POM_FILE}.tmp" "$POM_FILE"
    else
        echo "Warning: Could not find </plugins> or </build> tag in pom.xml"
    fi
fi

# Run OpenRewrite
echo "Running OpenRewrite migrations..."
mvn rewrite:run || {
    echo "OpenRewrite completed with warnings or errors"
    # Restore backup if rewrite failed completely
    if [ $? -ne 0 ]; then
        echo "Restoring pom.xml backup"
        mv "${POM_FILE}.backup" "$POM_FILE"
        exit 1
    fi
}

echo "OpenRewrite migration completed successfully"

