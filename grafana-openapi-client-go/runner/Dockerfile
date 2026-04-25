FROM docker.io/library/golang:latest AS build
WORKDIR /app
COPY go.mod .
COPY main.go .
ARG LIBRARY_VERSION
ENV GONOSUMDB="*"
ENV GOFLAGS="-mod=mod"
RUN if [ -n "$LIBRARY_VERSION" ]; then \
      go get github.com/grafana/grafana-openapi-client-go@${LIBRARY_VERSION}; \
    fi
RUN CGO_ENABLED=0 GOOS=linux go build -o runner .

FROM docker.io/library/alpine:3.19
COPY --from=build /app/runner /runner
ENTRYPOINT ["/runner"]
