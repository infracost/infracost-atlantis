ARG version
# Using latest release of Atlantis
<<<<<<< HEAD
FROM ghcr.io/runatlantis/atlantis:v0.18.2
=======
FROM ghcr.io/runatlantis/atlantis:${version}
>>>>>>> 0dc1fc9... chore: Update create-release GitHub workflow to use 3 last minor Atlantis releases

# Install required packages and latest 0.9 version of Infracost
RUN apk --update --no-cache add ca-certificates openssl openssh-client curl git jq
RUN \
  curl -s -L https://infracost.io/downloads/v0.9/infracost-linux-amd64.tar.gz | tar xz -C /tmp && \
  mv /tmp/infracost-linux-amd64 /usr/bin/infracost

### Legacy logic - not needed for new users
# The following logic is to support older infracost-atlantis users that used the atlantis_diff.sh script and compost.
# We do not plan to add new features to the old integration below so we recommend everyone to upgrade to the new
# usage methods mentioned in the README.
RUN apk --update --no-cache add nodejs npm
RUN \
  curl -s -L -o /home/atlantis/infracost_atlantis_diff.sh https://raw.githubusercontent.com/infracost/infracost/master/scripts/ci/atlantis_diff.sh && \
  chmod +x /home/atlantis/infracost_atlantis_diff.sh && \
  ln -s /home/atlantis/infracost_atlantis_diff.sh /infracost_atlantis_diff.sh && \
  npm install -g @infracost/compost
#### End of legacy logic
