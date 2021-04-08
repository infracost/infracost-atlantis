FROM runatlantis/atlantis:v0.16.1

# Install required packages
RUN apk --update --no-cache add ca-certificates openssl openssh-client curl git

# The jq package provided by alpine:3.13 (jq 1.6-rc1) is flagged as a 
# high severity vulnerability, so we install the latest release ourselves
# Reference: https://nvd.nist.gov/vuln/detail/CVE-2016-4074 (this is present on jq-1.6-rc1 as well)
RUN \
    # Install jq-1.6 (final release)
    curl -L -o /tmpjq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv /tmp/jq /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq

RUN \
  # Install latest infracost version
  curl -s -L https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz | tar xz -C /tmp && \
  mv /tmp/infracost-linux-amd64 /usr/bin/infracost && \
  # Fetch the atlantis_diff.sh script that runs infracost
  curl -s -L -o /home/atlantis/infracost_atlantis_diff.sh https://raw.githubusercontent.com/infracost/infracost/master/scripts/ci/atlantis_diff.sh && \
  chmod +x /home/atlantis/infracost_atlantis_diff.sh && \
  ln -s /home/atlantis/infracost_atlantis_diff.sh /infracost_atlantis_diff.sh
