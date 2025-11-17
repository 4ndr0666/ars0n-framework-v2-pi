# nuclei: requires Go >= 1.24
FROM golang:1.24 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/nuclei.git
WORKDIR /src/nuclei/v2/cmd/nuclei
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /nuclei

FROM alpine:3.19
COPY --from=build /nuclei /usr/bin/nuclei
ENTRYPOINT ["/usr/bin/nuclei"]
