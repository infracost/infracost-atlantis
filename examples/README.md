# Examples

This directory demonstrates how the integration can be setup using:
- [Combined Infracost comment](./combined-infracost-comment/README.md): combine cost estimates from multiple Terraform directories/workspaces into one Infracost pull request comment. Enables you to see the total cost estimate in one table. Only possible with Atlantis 0.18.2 or newer since it uses Atlantis' post_workflow_hooks feature.
- [Multiple Infracost comments](./multiple-infracost-comments/README.md): Post one Infracost pull request comment per Terraform directory/workspace. This is the best option for users who cannot upgrade Atlantis yet.
- [Append to Atlantis comment](./append-to-atlantis-comments/README.md): Append cost estimates to the bottom of Atlantis' "Show output" section of the pull request comment. Similar to the "multiple Infracost comments" option but the cost estimate is somewhat hidden. This is how our legacy integration worked but most users we talked to wanted option a combined Infracost comment.
- [Slack](./slack/README.md): post cost estimates to Slack

### Cost policy examples

- Checkout [this example](./conftest/README.md) to see how Atlantis' native Conftest integration can be used to check Infracost cost estimates against policies.
- If you do not use Conftest/Open Policy Agent, you can still set [thresholds](./thresholds/README.md) using bash and [jq](https://stedolan.github.io/jq/) so notifications or pull request comments are only sent when cost thresholds are exceeded.
