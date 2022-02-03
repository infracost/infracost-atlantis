# Examples

This directory demonstrates how the integration can be setup using:
- [Combined Infracost comment](./combined-infracost-comment/README.md): Combine cost estimates from multiple Terraform directories/workspaces into 1 Infracost pull request comment. Only possible with Atlantis 0.18.2 or newer since it uses Atlantis' post_workflow_hooks feature.
- [Multiple Infracost comments](./multiple-infracost-comments/README.md): Post one Infracost pull request comment per Terraform directory/workspace.
- [Append to Atlantis comment](./append-to-atlantis-comments/README.md): Append cost estimates to Atlantis pull request comment output
- [Slack](./slack/README.md): post cost estimates to Slack

### Cost policy examples

- Checkout [this example](./conftest/README.md) to see how Atlantis' native Conftest integration can be used to check Infracost cost estimates against policies.
- If you do not use Conftest/Open Policy Agent, you can still set [thresholds](./thresholds/README.md) using bash and [jq](https://stedolan.github.io/jq/) so notifications or pull request comments are only sent when cost thresholds are exceeded.
