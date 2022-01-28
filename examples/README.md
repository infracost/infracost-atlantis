# Examples

* [Single project PR comment](single_project) - This example shows how to use `infracost comment` with Atlantis to post a comment to an open PR with an Infracost result.
* [Thresholds](thresholds) - This example shows how to use `infracost comment` with Atlantis to post a comment when costs exceed set levels.
* [Terragrunt Project PR comment](terragrunt) - This example shows how to use `infracost comment` with atlantis and **Terragrunt** to post a comment to a comment to an open pr with a Infracost result.
* [Multi Project PR comment](single_project) - This example shows how to use `infracost comment` with Atlantis in a multi project repository. It posts a comment with Infracost results for every project in the repo.
* [Post a GitHub PR comment for a Terraform mono-repo](monorepo_github_comment) - This example shows how to use [compost](https://github.com/infracost/compost) with Atlantis and Infracost to post a comment with the Infracost result. This uses a pre-workflow hook to create a placeholder comment, which is then updated with the results as the workflow runs. The behavior of the comment can be changed by changing the `hide-and-new` argument in the pre-workflow hook.
* [Cost policies with Conftest](conftest) - This example shows how to use Atlantis' built in [Conftest](https://www.conftest.dev/) support with Infracost to enforce cost policies.
