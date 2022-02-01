# Examples

* [Single project PR comment](single_project) - This example shows how to use `infracost comment` with Atlantis to post a comment to an open PR with an Infracost result.
* [Multi-project, multiple PR comments](multi_project) - This example shows how to use `infracost comment` with Atlantis in a multi-project repository. It posts a comment with Infracost results for every project in the repo.
* [Multi-project, combined PR comment](multi_project_single_comment) - This example shows how to use `infracost comment` with Atlantis in a multi-project repository. It posts a single comment with Infracost results for every project with changes.
* [Terragrunt project PR comment](terragrunt) - This example shows how to use `infracost comment` with Atlantis and **Terragrunt** to post a comment to a comment to an open PR with a Infracost result.
* For private Terraform modules [see here](/README.md#private-terraform-modules)
* For Terraform Cloud/Enterprise [see here](/README.md#terraform-cloudenterprise)
* [Cost thresholds](thresholds) - This example shows how to use `infracost comment` with Atlantis to post a comment when costs exceed set levels.
* [Cost policies with Conftest](conftest) - This example shows how to use Atlantis' built-in [Conftest](https://www.conftest.dev/) support with Infracost to enforce cost policies.
* [Slack](slack) - This example shows how to send cost estimates to Slack.
* [Append to Atlantis comment](append_to_comment) - This example shows how to use Infracost with Atlantis to append Infracost cost output to an Atlantis comment.
