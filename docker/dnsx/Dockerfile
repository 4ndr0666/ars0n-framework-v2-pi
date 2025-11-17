FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/dnsx.git
WORKDIR /src/dnsx/cmd/dnsx
RUN CGO_ENABLED=0 go build -o /dnsx .

FROM alpine:3.19
COPY --from=build /dnsx /usr/bin/dnsx
ENTRYPOINT ["/usr/bin/dnsx"]
