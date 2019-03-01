FROM dalaymabboux/haskellnet as builder

WORKDIR /app

COPY . .

RUN stack --resolver lts-9.14 install && strip /root/.local/bin/Watchdog-exe

FROM fpco/haskell-scratch:integer-gmp

COPY --from=builder /root/.local/bin/Watchdog-exe /bin/

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 3000

CMD ["Watchdog-exe"]
