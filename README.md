# Infracost Atlantis Integration

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis. It automatically adds a comment to the bottom of Atlantis' output showing the cost estimate difference. See [this pull-request for a demo](https://github.com/infracost/atlantis-demo/pulls#issuecomment-795889174), expand the Show Output sections and scroll down to see the Infracost output.

This integration uses the latest version of Infracost by default as we regularly add support for more cloud resources. If you run into any issues, please join our [community Slack channel](https://www.infracost.io/community-chat); we'd be happy to guide you through it.

As mentioned in our [FAQ](https://www.infracost.io/docs/faq), no cloud credentials or secrets are sent to the Cloud Pricing API. Infracost does not make any changes to your Terraform state or cloud resources.

<img src="screenshot.png" width=557 alt="Example screenshot" />

## Table of Contents

* [Usage methods](#usage-methods)
  * [Docker image](#option-1-docker-image)
  * [Install in Docker](#option-2-install-in-docker)
* [Contributing](#contributing)

# Usage methods

There are three methods of integrating Infracost with Atlantis:
1. Use a custom Docker image that [extends](https://www.runatlantis.io/docs/deployment.html#customization) an Atlantis image to add Infracost (latest release, v0.9.16). This is the recommended method.

2. Use a pre-workflow hook to dynamically install the Infracost CLI on a running Atlantis server. 

3. Send the `$PLANFILE` from Atlantis to the Infracost [plan JSON API](https://www.infracost.io/docs/integrations/infracost_api) with `curl`. Whilst this API deletes files from the server after they are processed, it is a good security practice to remove secrets from the file before sending it to the API. For example, AWS provides [a grep command](https://gist.github.com/alikhajeh1/f2c3f607c44dabc70c73e04d47bb1307) that can be used to do this.

## Option 1: Docker image

[This Docker image](https://hub.docker.com/repository/docker/infracost/infracost-atlantis/) extends the Atlantis image by adding the Infracost CLI. If you already use a custom Docker image for Atlantis, copy the `RUN` commands from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

The `infracost-atlantis` image is maintained with tags for the latest three 0.x versions of Atlantis. For example, if the latest 0.x versions of Atlantis are v0.18.1, v0.17.6, and v0.16.1, the following images will be published/updated when Infracost v0.9.17 is released:
 
- infracost-atlantis:atlantis0.16-infracost0.9 with Atlantis v0.18.1 and Infracost v0.9.17 
- infracost-atlantis:atlantis0.17-infracost0.9 with Atlantis v0.17.6 and Infracost v0.9.17
- infracost-atlantis:atlantis0.18-infracost0.9 with Atlantis v0.16.1 and Infracost v0.9.17
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

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
