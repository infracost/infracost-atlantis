# Infracost Atlantis Integration

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis. It automatically adds a comment to the bottom of Atlantis' output showing the cost estimate difference. See [this pull-request for a demo](https://github.com/infracost/atlantis-demo/pulls#issuecomment-795889174), expand the Show Output sections and scroll down to see the Infracost output.

This integration uses the latest version of Infracost by default as we regularly add support for more cloud resources. If you run into any issues, please join our [community Slack channel](https://www.infracost.io/community-chat); we'd be happy to guide you through it.

As mentioned in our [FAQ](https://www.infracost.io/docs/faq), no cloud credentials or secrets are sent to the Cloud Pricing API. Infracost does not make any changes to your Terraform state or cloud resources.

<img src="screenshot.png" width=557 alt="Example screenshot" />

## Table of Contents

* [Usage methods](#usage-methods)
  * [Docker image](#option-1-docker-image)
  * [Install in Docker](#option-2-install-in-docker)
* [Project examples](#project-examples)
* [Contributing](#contributing)

# Usage methods

There are three methods of integrating Infracost with Atlantis:
1. Use a custom Docker image that [extends](https://www.runatlantis.io/docs/deployment.html#customization) an Atlantis image to add Infracost (latest release, v0.9.16). This is the recommended method.

2. Use a pre-workflow hook to dynamically install the Infracost CLI on a running Atlantis server.

3. Send the `$PLANFILE` from Atlantis to the Infracost [plan JSON API](https://www.infracost.io/docs/integrations/infracost_api) with `curl`. Whilst this API deletes files from the server after they are processed, it is a good security practice to remove secrets from the file before sending it to the API. For example, AWS provides [a grep command](https://gist.github.com/alikhajeh1/f2c3f607c44dabc70c73e04d47bb1307) that can be used to do this.

## Option 1: Docker image

[This Docker image](https://hub.docker.com/repository/docker/infracost/infracost-atlantis/) extends the Atlantis image by adding the Infracost CLI. If you already use a custom Docker image for Atlantis, copy the `RUN` commands from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

The `infracost-atlantis` image is maintained with tags for the latest three 0.x versions of Atlantis. For example, if the latest 0.x versions of Atlantis are v0.18.1 and v0.17.6, the following images will be published/updated when Infracost v0.9.17 is released:

- infracost-atlantis:atlantis0.18-infracost0.9 with Atlantis v0.18.1 and Infracost v0.9.17
- infracost-atlantis:atlantis0.17-infracost0.9 with Atlantis v0.17.6 and Infracost v0.9.17
- infracost-atlantis:latest with Atlantis v0.18.1 and Infracost v0.9.17

To generate cost estimates, update your Atlantis configuration to add a [custom command](https://www.runatlantis.io/docs/custom-workflows.html#running-custom-commands) that runs Infracost with the required environment variables, such as `INFRACOST_API_KEY`. The following simple example adds the Infracost cost estimate to the Atlantis output. See [the examples section](examples) for more advanced configurations.

```
docker run -p 4141:4141 -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
  infracost/infracost-atlantis:latest server \
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
                "run": "terraform show -json $PLANFILE > $SHOWFILE"
              },
              {
                "run": "echo \"#####\" && echo && echo Infracost output:"
              },
              {
                "run": "infracost diff --path $SHOWFILE --no-color --log-level=warn"
              }
            ]
          }
        }
      }
    }
  '
```

To test, send a new pull request to change something in Terraform that costs money; a comment should be posted on the pull request by Atlantis. Expand the Show Output section, at the bottom of which you should see the Infracost output.

## Option 2: Install in Docker

Instead of baking Infracost into the Dockerfile, it can be installed dynamically in a pre-workflow hook such as:

```yaml
repos:
  - id: /.*/
    workflow: terraform-infracost
    pre_workflow_hooks:
      # Install Infracost
      - run: |
          /tmp/infracost --version && [ $(/tmp/infracost --version 2>&1 | grep -c "A new version of Infracost is available") = 0 ] || \
            curl -L https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz --output infracost.tar.gz && \
            tar -xvf infracost.tar.gz && \
            mv infracost-linux-amd64 /tmp/infracost
```

For example, to use the Infracost CLI with the latest official Atlantis image, add the pre-workflow hook and set the required environment variables, such as `INFRACOST_API_KEY`. The following simple example adds the Infracost cost estimate to the Atlantis output. See [the examples section](examples) for more advanced configurations.

    ```
    docker run -p 4141:4141 -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
      ghcr.io/runatlantis/atlantis:latest server \
      --gh-user=MY_GITHUB_USERNAME \
      --gh-token=MY_GITHUB_TOKEN \
      --gh-webhook-secret=MY_GITHUB_WEBHOOK_SECRET \
      --repo-allowlist='github.com/myorg/*' \
      --repo-config-json='
        {
          "repos": [
            {
              "id": "/.*/",
              "workflow": "terraform-infracost",
              "pre_workflow_hooks": [
                { "run": "/tmp/infracost --version && [ $(/tmp/infracost --version 2>&1 | grep -c "A new version of Infracost is available") = 0 ] || curl -L https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz --output infracost.tar.gz && tar -xvf infracost.tar.gz && mv infracost-linux-amd64 /tmp/infracost" }
              ]
            }
          ],
          "workflows": {
            "terraform-infracost": {
              "plan": {
                "steps": [
                  "init",
                  "plan",
                  {
                    "run": "terraform show -json $PLANFILE > $SHOWFILE"
                  },
                  {
                    "run": "echo \"#####\" && echo && echo Infracost output:"
                  },
                  {
                    "run": "/tmp/infracost diff --path $SHOWFILE --no-color --log-level=warn"
                  }
                ]
              }
            }
          }
        }
      '
    ```

To test, send a new pull request to change something in Terraform that costs money; a comment should be posted on the pull request by Atlantis. Expand the Show Output section, at the bottom of which you should see the Infracost output.

# Project Examples

To help you get up and running with Infracost and Atlantis as quick as possible, we've compiled a list of commonly used scenarios.

* [Single Project](./examples/single_project/README.md)
* [Cost Thresholds](./examples/thresholds/README.md)

# Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Running Infracost Atlantis Docker image locally

Follow these steps to get the `infracost-atlantis` Docker image working locally with GitHub.

1. Clone the [infracost](https://github.com/infracost/infracost) repo
2. Clone this repo and `cd` into it
3. Make sure the `atlantis.env` file is filled out with the correct values.
   1. `ATLANTIS_GH_TOKEN` & `GITHUB_TOKEN` needs to be set to a personal GitHub access token with repo access
   2. `ATLANTIS_GH_WEBHOOK_SECRET` can be any long string - see step 8 for more into
   3. `ATLANTIS_REPO_ALLOWLIST` needs to be the repo you wish to test PR commenting on
   4. `INFRACOST_API_KEY` needs to be a valid Infracost api key
4. Place a `repos.yaml` file in the root of the project that contains the workflows you wish to test
5. Run `./docker-compose-dev.sh` setting `INFRACOST_REPO` variable to point to the relative path of the `infracost` repo
6. Create a test GitHub repository, populating it with a single `main.tf` file with [this content](https://github.com/infracost/gh-actions-demo/blob/master/terraform/main.tf).
7. Run `curl $(docker port infracost-atlantis_ngrok_1 4040)/api/tunnels | jq ."tunnels" | jq '.[0]' | jq ."public_url"` to get the public url of the ngrok tunnel to your local atlantis
8. Navigate to Settings > Webhooks > Add webhook
   1. Set the 'Payload URL' to the URL from the previous step + `/events` path
   2. For 'Content type' select 'application/json'
   3. For 'Which events would you like to trigger this webhook?' select 'Let me select individual events' and tick 'Pull requests', 'Issue comments' and 'Pushes'.
9. Make a change to the `main.tf` file and open a PR with it
10. If everything has run successfully you should see an output on your PR with Infracost results


# License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
