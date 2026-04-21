# Giai đoạn 1: Build
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# 1. Build profile-service
COPY services/profile-service ./services/profile-service
RUN mvn clean package -f services/profile-service/pom.xml -DskipTests

# Giai đoạn 2: Chạy
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/services/profile-service/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
