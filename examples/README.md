# Examples

* [Post a GitHub PR comment for a Terraform mono-repo](monorepo_github_comment.yml) - This example shows how to use [compost](https://github.com/infracost/compost) with Atlantis and Infracost to post a comment with the Infracost result. This uses a pre-workflow hook to create a placeholder comment, which is then updated with the results as the workflow runs. The behavior of the comment can be changed by changing the `hide-and-new` argument in the pre-workflow hook.
