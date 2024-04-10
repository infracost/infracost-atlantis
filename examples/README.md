# Examples

This directory demonstrates how the integration can be setup using:
- [Infracost comment](./infracost-comment/README.md): combine cost estimates from multiple Terraform directories/workspaces into one Infracost pull request comment.
- [Slack](./slack/README.md): post cost estimates to Slack

### Cost policy examples

- Check out [this example](./conftest/README.md) to see how Atlantis' native Conftest integration can be used to check Infracost cost estimates against policies.
- If you do not use Conftest/Open Policy Agent, you can still set [thresholds](./thresholds/README.md) using bash and [jq](https://stedolan.github.io/jq/) so notifications or pull request comments are only sent when cost thresholds are exceeded.
