# Using latest release of Atlantis
FROM runatlantis/atlantis:v0.16.0

# Install required packages
RUN apk --update --no-cache add ca-certificates openssl openssh-client curl git jq

RUN \
  # Install latest infracost version
  curl -s -L https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz | tar xz -C /tmp && \
  mv /tmp/infracost-linux-amd64 /usr/bin/infracost && \
  # Fetch the atlantis_diff.sh script that runs infracost
  curl -s -L -o /infracost_atlantis_diff.sh https://raw.githubusercontent.com/infracost/infracost/feat/atlantis/scripts/ci/atlantis_diff.sh && \
  chmod +x /infracost_atlantis_diff.sh
