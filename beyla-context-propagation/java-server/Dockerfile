FROM docker.io/library/eclipse-temurin:21-jdk

WORKDIR /app
COPY Server.java .
RUN javac Server.java

CMD ["java", "Server"]