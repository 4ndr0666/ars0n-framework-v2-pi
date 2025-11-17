FROM golang:1.21.3 as build
WORKDIR /src/katana
RUN git clone https://github.com/projectdiscovery/katana.git . && \
    go build -o /katana

FROM alpine:3.18
COPY --from=build /katana /katana
ENTRYPOINT ["/katana"]