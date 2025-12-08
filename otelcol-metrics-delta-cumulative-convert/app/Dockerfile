FROM docker.io/library/golang:1.25.3

WORKDIR /app

COPY go.mod go.sum* ./

RUN --mount=type=cache,target=/go/pkg go mod download && go mod verify

COPY ./*.go .

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    go build -o rolldice

ENTRYPOINT ["/app/rolldice"]
