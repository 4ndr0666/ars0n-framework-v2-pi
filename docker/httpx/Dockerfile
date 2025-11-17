FROM golang:1.21.3 as build
WORKDIR /src/httpx
RUN git clone https://github.com/projectdiscovery/httpx.git . && \
    go build -o /httpx

FROM alpine:3.18
COPY --from=build /httpx /httpx
ENTRYPOINT ["/httpx"]