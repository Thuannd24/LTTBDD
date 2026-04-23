# Giai đoạn 1: Build
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# Sao chép và build Eureka Server
COPY services/eureka-server ./services/eureka-server
RUN mvn clean package -f services/eureka-server/pom.xml -Dmaven.test.skip=true

# Giai đoạn 2: Chạy
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/services/eureka-server/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
