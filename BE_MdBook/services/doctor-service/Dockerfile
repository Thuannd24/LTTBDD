# Giai đoạn 1: Build
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# 1. Build shared-protos trước
COPY shared-protos ./shared-protos
RUN mvn clean install -f shared-protos/pom.xml -DskipTests

# 2. Build doctor-service
COPY services/doctor-service ./services/doctor-service
RUN mvn clean package -f services/doctor-service/pom.xml -DskipTests

# Giai đoạn 2: Chạy
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/services/doctor-service/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
