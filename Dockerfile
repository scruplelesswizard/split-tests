FROM alpine as build

RUN apk add --no-cache curl gzip

RUN curl -L "https://github.com/leonid-shevtsov/split_tests/releases/latest/download/split_tests.linux.gz" | gunzip -v > split_tests

RUN chmod +x /split_tests

FROM scratch

COPY --from=build /split_tests /split_tests

ENTRYPOINT [ "/split_tests" ]
