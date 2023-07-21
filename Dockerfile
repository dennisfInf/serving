FROM golang:latest as build-env

ENV CGO_ENABLED=0

COPY . /app/
WORKDIR /app/

RUN go build -o backend -ldflags="-extldflags=-static -w" ./cmd/controller/

FROM gcr.io/distroless/static:nonroot

COPY --from=build-env \
    /app/backend \
    /app/
    
WORKDIR /app/

ENTRYPOINT [ "/app/backend" ]
