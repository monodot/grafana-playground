FROM docker.io/library/eclipse-temurin:21-jdk AS build
WORKDIR /build
COPY src/App.java .
RUN javac -d /out App.java

FROM docker.io/library/eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /out /app
ENTRYPOINT ["java", "-cp", "/app", "App"]
