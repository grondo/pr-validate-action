FROM alpine:3.10
COPY check-pr-commits.sh /check-pr-commits.sh
ENTRYPOINT ["/check-pr-commits.sh"]
