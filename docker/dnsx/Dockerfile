FROM golang:1.21.3 as build
WORKDIR /src/dnsx
RUN git clone https://github.com/projectdiscovery/dnsx.git . && \
    go build -o /dnsx

FROM alpine:3.18
COPY --from=build /dnsx /dnsx
ENTRYPOINT ["/dnsx"]