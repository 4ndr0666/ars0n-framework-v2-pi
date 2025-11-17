FROM golang:1.21 as build
WORKDIR /src/assetfinder
RUN git clone https://github.com/tomnomnom/assetfinder.git . && \
    go install -ldflags="-s -w" ./...

FROM alpine:3.18
COPY --from=build /assetfinder /assetfinder
ENTRYPOINT ["/assetfinder"]