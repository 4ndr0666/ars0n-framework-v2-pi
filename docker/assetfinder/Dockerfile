FROM golang:1.21 as build

WORKDIR /src/assetfinder
RUN git clone https://github.com/tomnomnom/assetfinder.git . && \
    GO111MODULE=off go build -o /assetfinder

FROM alpine:3.18
COPY --from=build /assetfinder /assetfinder
ENTRYPOINT ["/assetfinder"]