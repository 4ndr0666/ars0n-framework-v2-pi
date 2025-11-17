FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/katana.git
WORKDIR /src/katana/cmd/katana
RUN CGO_ENABLED=0 go build -o /katana .

FROM alpine:3.19
COPY --from=build /katana /usr/bin/katana
ENTRYPOINT ["/usr/bin/katana"]
