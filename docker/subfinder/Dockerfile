FROM golang:1.21.4 as build
WORKDIR /src/subfinder
RUN git clone https://github.com/projectdiscovery/subfinder.git . && \
    go build -o /subfinder

FROM alpine:3.18
COPY --from=build /subfinder /subfinder
ENTRYPOINT ["/subfinder"]