ARG version
# Using latest release of Atlantis
FROM ghcr.io/runatlantis/atlantis:${version}

# Install required packages
RUN apk --update --no-cache add ca-certificates openssl openssh-client curl git jq nodejs npm

# Install latest infracost version
RUN \
  curl -s -L https://infracost.io/downloads/latest/infracost-linux-amd64.tar.gz | tar xz -C /tmp && \
  mv /tmp/infracost-linux-amd64 /usr/bin/infracost

# The following logic is to support older infracost-atlantis users that used the atlantis_diff.sh script and compost.
# We do not plan to add new features to the old integration below so we recommend everyone to upgrade to the new
# usage methods mentioned in the README.
RUN \
  curl -s -L -o /home/atlantis/infracost_atlantis_diff.sh https://raw.githubusercontent.com/infracost/infracost/master/scripts/ci/atlantis_diff.sh && \
  chmod +x /home/atlantis/infracost_atlantis_diff.sh && \
  ln -s /home/atlantis/infracost_atlantis_diff.sh /infracost_atlantis_diff.sh && \
  npm install -g @infracost/compost
