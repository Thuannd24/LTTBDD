# Giai đoạn 1: Build
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# 1. Build identity-service
COPY services/identity-service ./services/identity-service
RUN mvn clean package -f services/identity-service/pom.xml -Dmaven.test.skip=true

# Giai đoạn 2: Chạy
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/services/identity-service/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
