FROM docker.io/library/eclipse-temurin:21-jdk

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* && \
    curl -L https://jdbc.postgresql.org/download/postgresql-42.7.4.jar -o postgresql.jar

COPY Server.java .
RUN javac -cp postgresql.jar Server.java

CMD ["java", "-cp", ".:postgresql.jar", "Server"]