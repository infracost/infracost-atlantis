# Infracost Atlantis Integration

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis. It automatically adds a comment to the bottom of Atlantis' output showing the cost estimate difference (similar to `git diff`) if a percentage threshold is crossed. See [this pull-request for a demo](https://github.com/infracost/infracost-atlantis/pull/2#issuecomment-773427685), expand the Show Output sections and scroll down to see the Infracost output.

This integration uses the latest version of Infracost by default as we regularly add support for more cloud resources. If you run into any issues, please join our [community Slack channel](https://www.infracost.io/community-chat); we'd be happy to guide you through it.

As mentioned in the [FAQ](https://www.infracost.io/docs/faq), you can run Infracost in your Terraform directories without worrying about security or privacy issues as no cloud credentials, secrets, tags or Terraform resource identifiers are sent to the open-source [Cloud Pricing API](https://github.com/infracost/cloud-pricing-api). Infracost does not make any changes to your Terraform state or cloud resources.

<img src="screenshot.png" width=557 alt="Example screenshot" />

# Usage methods

There are two methods of integrating Infracost with Atlantis:
1. Use a custom Docker image that [extends](https://www.runatlantis.io/docs/deployment.html#customization) Atlantis' `latest` image to add Infracost. This is the recommended method.

2. Send the `$PLANFILE` from Atlantis to the [Infracost API](https://www.infracost.io/docs/infracost_api) with `curl`. Whilst this API deletes files from the server after they are processed, it is a good security practice to remove secrets from the file before sending it to the API. For example, AWS provides [a grep command](https://gist.github.com/alikhajeh1/f2c3f607c44dabc70c73e04d47bb1307) that can be used to do this.

## 1. Docker image

This method runs Infracost using the [Terraform directory method](https://www.infracost.io/docs/#1-terraform-directory) in each of the Terraform projects managed by Atlantis. Once [this issue](https://github.com/infracost/infracost/issues/394) is released, we'll update this integration to use the `$PLANFILE` that Atlantis generates; that simplifies the integration to remove the need for passing in Terraform flags or setting the `TERRAFORM_BINARY` for Terragrunt users.

The following steps describe how you can use this method:

1. [This Docker image](https://hub.docker.com/repository/docker/infracost/infracost-atlantis/) extends the Atlantis image by adding the Infracost CLI and the [`infracost_atlantis_diff.sh`](https://github.com/infracost/infracost/blob/master/scripts/ci/atlantis_diff.sh) script. If you already use a custom Docker image for Atlantis, copy the `RUN` commands from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

2. Update your Atlantis configuration to add a [custom command](https://www.runatlantis.io/docs/custom-workflows.html#running-custom-commands) that runs Infracost with the required environment variables, such as `INFRACOST_API_KEY` and `terraform_plan_flags`. The available environment variables are describe in the next section. The following example shows how this can be done, a similar thing can be done with the Atlantis yaml configs in either the Server Config file or Server Side Repo Config files. 

    ```
    docker run infracost/infracost-atlantis:latest server \
      --gh-user=MY_GITHUB_USERNAME \
      --gh-token=MY_GITHUB_TOKEN \
      --gh-webhook-secret=MY_GITHUB_WEBHOOK_SECRET \
      --repo-allowlist='github.com/myorg/*' \
      --repo-config-json='
        {
          "repos": [
            {
              "id": "/.*/",
              "workflow": "terraform-infracost"
            }
          ],
          "workflows": {
            "terraform-infracost": {
              "plan": {
                "steps": [
                  "init",
                  "plan",
                  {
                    "env": {
                      "name": "INFRACOST_API_KEY",
                      "value": "MY_API_KEY"
                    }
                  },
                  {
                    "env": {
                      "name": "terraform_plan_flags",
                      "value": "-var-file=myvars.tfvars -var-file=othervars.tfvars"
                    }
                  },
                  {
                    "run": "/infracost_atlantis_diff.sh"
                  }
                ]
              }
            }
          }
        }
      '
    ```

3. Send a new pull request to change something in Terraform that costs money; a comment should be posted on the pull request by Atlantis, expand the Show Output section, at the bottom of which you should see the Infracost output. Set the `atlantis_debug=true` environment variable if there are issues so you can debug.

### Environment variables

The following environment variables are supported. Other supported environment variables are described in the [Infracost docs](https://www.infracost.io/docs/environment_variables). 

Terragrunt users should also read [this section](https://www.infracost.io/docs/terragrunt). Terraform Cloud/Enterprise users should also read [this section](https://www.infracost.io/docs/terraform_cloud_enterprise)

#### `INFRACOST_API_KEY`

**Required** To get an API key [download Infracost](https://www.infracost.io/docs/#installation) and run `infracost register`.

#### `INFRACOST_TERRAFORM_BINARY`

**Optional** Used to change the path to the terraform binary or version, should be set to the path of the Terraform or Terragrunt binary being used in Atlantis.

#### `terraform_plan_flags`

**Optional** Flags to pass to the 'terraform plan' command run by Infracost, e.g. `"-var-file=myvars.tfvars -var-file=othervars.tfvars"`.

#### `usage_file`

**Optional** Path to Infracost [usage file](https://www.infracost.io/docs/usage_based_resources#infracost-usage-file) that specifies values for usage-based resources, see [this example file](https://github.com/infracost/infracost/blob/master/infracost-usage-example.yml) for the available options. The file should be present in the master/main branch too.

#### `percentage_threshold`

**Optional** The absolute percentage threshold that triggers a pull request comment with the diff. Defaults to 0, meaning that a comment is posted if the cost estimate changes. For example, set to 5 to post a comment if the cost estimate changes by plus or minus 5%.

#### `pricing_api_endpoint`

**Optional** Specify an alternate Cloud Pricing API URL (default is https://pricing.api.infracost.io).

#### `atlantis_debug`

**Optional** Enable debug mode in [`infracost_atlantis_diff.sh`](https://github.com/infracost/infracost/blob/master/scripts/ci/atlantis_diff.sh) so it shows the steps being run in the Atlantis pull request comment (default is false).

## 2. Infracost API

Currently this method uses the [Infracost API](https://www.infracost.io/docs/infracost_api) and shows the full Infracost table output instead of a diff; once [this issue](https://github.com/infracost/infracost/issues/394) is released, we'll update this method to return a diff.

1. Update your Atlantis configuration to add a [custom command](https://www.runatlantis.io/docs/custom-workflows.html#running-custom-commands) that runs Infracost as shown in the following example. You should only need to update `MY_API_KEY` to your Infracost API key. A similar thing can be done with the Atlantis yaml configs in either the Server Config file or Server Side Repo Config files. Optionally add a step to remove secrets from the plan JSON file before sending it to the API.

  ```
  docker run infracost/infracost-atlantis:latest server \
    --gh-user=MY_GITHUB_USERNAME \
    --gh-token=MY_GITHUB_TOKEN \
    --gh-webhook-secret=MY_GITHUB_WEBHOOK_SECRET \
    --repo-allowlist='github.com/myorg/*' \
    --repo-config-json='
      {
        "repos": [
          {
            "id": "/.*/",
            "workflow": "terraform-infracost"
          }
        ],
        "workflows": {
          "terraform-infracost": {
            "plan": {
              "steps": [
                "init",
                "plan",
                {
                  "run": "terraform show -json $PLANFILE > $PLANFILE.json"
                },
                {
                  "run": "echo \"#####\" && echo && echo Infracost output:"
                },
                {
                  "run": "curl -s -X POST -H \"x-api-key: MY_API_KEY\" -F \"ci-platform=atlantis\" -F \"terraform-json-file=@$PLANFILE.json\" -F \"no-color=true\" https://pricing.api.infracost.io/terraform-json-file"
                },
                {
                  "run": "rm -rf $PLANFILE.json"
                }
              ]
            }
          }
        }
      }
    '
  ```

2. Send a new pull request to change something in Terraform that costs money; a comment should be posted on the pull request by Atlantis, expand the Show Output section, at the bottom of which you should see the Infracost output. The output should include errors if there are issues.

## Contributing

Merge requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
