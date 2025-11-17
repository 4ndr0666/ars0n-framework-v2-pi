FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/jaeles-project/gospider.git .
RUN CGO_ENABLED=0 go build -o /gospider .

FROM alpine:3.19
COPY --from=build /gospider /usr/bin/gospider
ENTRYPOINT ["/usr/bin/gospider"]