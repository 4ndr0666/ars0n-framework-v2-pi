# assetfinder: disable modules and update Go
FROM golang:1.24 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/tomnomnom/assetfinder.git

# assetfinder uses GOPATH layout; disable module mode
WORKDIR /src/assetfinder
ENV GO111MODULE=off
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /assetfinder

FROM alpine:3.19
COPY --from=build /assetfinder /usr/bin/assetfinder
ENTRYPOINT ["/usr/bin/assetfinder"]
