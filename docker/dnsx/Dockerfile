# dnsx: requires Go >= 1.24
FROM golang:1.24 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/dnsx.git
WORKDIR /src/dnsx/cmd/dnsx
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /dnsx

FROM alpine:3.19
COPY --from=build /dnsx /usr/bin/dnsx
ENTRYPOINT ["/usr/bin/dnsx"]
