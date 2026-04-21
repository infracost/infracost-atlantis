# Set this to the version of Atlantis you want to use
ARG version=latest
FROM ghcr.io/runatlantis/atlantis:${version}

# Set to root user so we can install packages
USER root

# Set this to the minor version of Infracost CLI you want to use (e.g., v0.9, v0.10)
ARG cli_version=v0.10

# Install required packages and latest ${cli_version} version of Infracost
RUN apk --update --no-cache add ca-certificates openssl openssh-client curl git jq

# Download and install the correct Infracost binary based on the target architecture
ARG TARGETARCH
RUN \
  curl -s -L "https://infracost.io/downloads/$cli_version/infracost-linux-${TARGETARCH}.tar.gz" | tar xz -C /tmp && \
  mv /tmp/infracost-linux-${TARGETARCH} /usr/bin/infracost

# Restore the atlantis user
USER atlantis
