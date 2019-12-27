FROM alpine:3.10
RUN apk add --no-cache \
  bash \
  git
COPY check-pr-commits.sh /check-pr-commits.sh
ENTRYPOINT ["/bin/bash", "/check-pr-commits.sh"]
