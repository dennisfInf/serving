FROM golang:latest as build-env

ENV CGO_ENABLED=0

COPY . /app/
WORKDIR /app/

RUN go build -o app -ldflags="-extldflags=-static -w" ./cmd/queue/

FROM gramineproject/gramine:v1.4
RUN apt-get update && apt-get install -y --no-install-recommends libsgx-dcap-default-qpl xxd && rm -rf /var/lib/apt/lists/*
COPY --from=build-env \
    /app/app \
    /app/
COPY ./sgx/app.manifest.template /entrypoint/
COPY ./sgx/entrypoint.sh /entrypoint/
COPY ./sgx/sgx_default_qcnl.conf /etc/    
WORKDIR /entrypoint/
RUN gramine-sgx-gen-private-key 
RUN gramine-manifest -Darch_libdir=/lib/x86_64-linux-gnu app.manifest.template app.manifest 
RUN gramine-sgx-sign --manifest app.manifest --output app.manifest.sgx
RUN gramine-sgx-get-token --output app.token --sig app.sig
# Running as root, because security context must be set to privileged.
ENTRYPOINT [ "/entrypoint/entrypoint.sh"  ]
