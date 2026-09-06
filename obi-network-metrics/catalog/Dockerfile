FROM docker.io/library/golang:1.25.3 AS build

WORKDIR /src
COPY go.mod ./
COPY main.go ./

# Make a Go-only binary, remove local filesystem paths from binary, strip symbol tables and debug info (-w)
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /catalog .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /catalog /catalog
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/catalog"]
