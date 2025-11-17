# subfinder: requires Go >= 1.24
FROM golang:1.24 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/subfinder.git
WORKDIR /src/subfinder/v2/cmd/subfinder
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /subfinder

FROM alpine:3.19
COPY --from=build /subfinder /usr/bin/subfinder
ENTRYPOINT ["/usr/bin/subfinder"]
