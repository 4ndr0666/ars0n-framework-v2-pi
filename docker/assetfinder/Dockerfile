FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/tomnomnom/assetfinder.git
WORKDIR /src/assetfinder
RUN CGO_ENABLED=0 go build -o /assetfinder

FROM alpine:3.19
COPY --from=build /assetfinder /usr/bin/assetfinder
ENTRYPOINT ["/usr/bin/assetfinder"]
