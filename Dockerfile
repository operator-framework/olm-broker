FROM golang:1.10 as builder
#FROM quay.io/coreos/alm-ci:base as builder
LABEL builder=true
WORKDIR /go/src/github.com/operator-framework/olm-broker
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /bin/jq
RUN chmod +x /bin/jq
# Cache Dep first
COPY Gopkg.toml Gopkg.lock Makefile ./
RUN make vendor
COPY . .
RUN make build
# TODO: add tests
#RUN go test -c -o /bin/e2e ./test/e2e/...

FROM alpine:latest as broker
LABEL broker=true
WORKDIR /
COPY --from=builder /go/src/github.com/operator-framework/olm-broker/bin/servicebroker /bin/servicebroker
EXPOSE 8080
EXPOSE 8005
CMD ["/bin/servicebroker"]
