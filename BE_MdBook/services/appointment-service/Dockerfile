# Giai đoạn 1: Build
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# 1. Build appointment-service
COPY services/appointment-service ./services/appointment-service
RUN mvn clean package -f services/appointment-service/pom.xml -Dmaven.test.skip=true

# Giai đoạn 2: Chạy
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/services/appointment-service/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
