# Infracost Atlantis Integration

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis, so you can see cloud cost estimates for Terraform in pull requests 💰 

TODO: Update screenshot to show an Atlantis comment next to an Infracost comment, layered on top of each other, similar to https://github.com/infracost/actions - we could update https://github.com/infracost/atlantis-demo to have a demo PR and take a screenshot from there
<img src="screenshot.png" width=570 alt="Example screenshot" />

## Usage methods

Since Atlantis does not have a plugins concept, you need to make two decisions to integrate it with Infracost:

1. Which deployment option do you want to use?
  
    a) **Use our Docker images (recommended)**: use our [`infracost-atlantis`](https://hub.docker.com/repository/docker/infracost/infracost-atlantis/) Docker images that [extend](https://www.runatlantis.io/docs/deployment.html#customization) the Atlantis image to add Infracost. We maintain tags for the latest two 0.x versions of Atlantis:
      - `infracost/infracost-atlantis:atlantis0.18-infracost0.9` latest patch version of Atlantis v0.18 and Infracost v0.9
      - `infracost/infracost-atlantis:atlantis0.17-infracost0.9` latest patch version of Atlantis v0.17 and Infracost v0.9
      - `infracost/infracost-atlantis:latest` latest versions of Atlantis and Infracost

    b) **Build your own Docker image**: if you already use a custom Docker image for Atlantis, copy the `RUN` commands from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

    c) **Install in pre-workflow (good for testing)**: use an Atlantis `pre_workflow_hook` to dynamically install the Infracost CLI on a running Atlantis server (shown in the following repos.yml example). This enables you to test Infracost without changing your Docker image, and once you're happy with the results you can use one of the above methods. We only recommend this option for testing as the CLI is installed on each workflow run. If you use `infracost comment` to post pull request comments, you also need to pass the required environment variables to the Atlantis process - the examples in the next step show this.

      ```yaml
      repos:
        - id: /.*/
          workflow: terraform-infracost
          pre_workflow_hooks:
            # Install Infracost
            - run: |
                /tmp/infracost --version && [ $(/tmp/infracost --version 2>&1 | grep -c "A new version of Infracost is available") = 0 ] || \
                  curl -L https://infracost.io/downloads/v0.9/infracost-linux-amd64.tar.gz --output infracost.tar.gz && \
                  tar -xvf infracost.tar.gz && \
                  mv infracost-linux-amd64 /tmp/infracost
      ```

2. Which option do you want to use for handling multiple Terraform directories/workspaces?

    |  | If you're using Atlantis 0.18.2 or newer | If you're using older than Atlantis 0.18.2 |
    | --- | --- | --- |
    | Combine cost estimates from multiple Terraform directories/workspaces into 1 Infracost pull request comment | [Use this example](./examples/combined-infracost-comment/README.md) | Not possible since post_workflow_hooks were added in Atlantis 0.18.2 |
    | Post one Infracost pull request comment per Terraform directory/workspace | [Use this example](./examples/multiple-infracost-comments/README.md) | [Use this example](./examples/multiple-infracost-comments/README.md) |
    | Append cost estimates to Atlantis pull request comment output | [Use this example](./examples/append-to-atlantis-comments/README.md) | [Use this example](./examples/append-to-atlantis-comments/README.md) |

## Examples

The [examples](examples) directory demonstrates how the integration can be setup:
- [Combined Infracost comment](./examples/combined-infracost-comment/README.md): Combine cost estimates from multiple Terraform directories/workspaces into 1 Infracost pull request comment. Only possible with Atlantis 0.18.2 or newer since it uses Atlantis' post_workflow_hooks feature.
- [Multiple Infracost comments](./examples/multiple-infracost-comments/README.md): Post one Infracost pull request comment per Terraform directory/workspace.
- [Append to Atlantis comment](./examples/append-to-atlantis-comments/README.md): Append cost estimates to Atlantis pull request comment output
- [Slack](./examples/slack/README.md): post cost estimates to Slack

### Cost policy examples

- Checkout [this example](./examples/conftest/README.md) to see how Atlantis' native Conftest integration can be used to check Infracost cost estimates against policies.
- If you do not use Conftest/Open Policy Agent, you can still set [thresholds](./examples/thresholds/README.md) using bash and [jq](https://stedolan.github.io/jq/) so notifications or pull request comments are only sent when cost thresholds are exceeded.

## Atlantis usage notes

### Private Terraform modules

To use with Terraform modules that are hosted in a private git repository you can add the `--write-git-creds` flag to your `atlantis server` command.

### Terraform Cloud/Enterprise

To use with Terraform Cloud/Enterprise you can add the following flags to your `atlantis server` command: `--tfe-hostname='MY_TFE_HOSTNAME' --tfe-token='MY_TFE_TOKEN'`.

### Terragrunt

TODO: does this need more details?

If you use Atlantis with Terragrunt, you should:

1. Update your Docker image to include `terragrunt`, for example:

   ```dockerfile
   FROM infracost/infracost-atlantis:latest

   RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.0/terragrunt_linux_amd64 --output terragrunt && \
       chmod +x terragrunt && \
       mv terragrunt /usr/local/bin
   ```

2. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files, altering it to fit your terragrunt project:

    ```yaml
    repos:
      - id: /.*/
        workflow: terragrunt-infracost
    workflows:
      terragrunt-infracost:
        plan:
          steps:
            - env:
                name: INFRACOST_OUTPUT
                command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json"'
            - env:
                name: TERRAGRUNT_TFPATH
                command: 'echo "terraform${ATLANTIS_TERRAFORM_VERSION}"'
            - run: terragrunt plan -out=$PLANFILE
            - run: terragrunt show -json $PLANFILE > $SHOWFILE
            # Add custom steps here from the examples mentioned elsewhere in this readme
    ```

## Contributing

Issues and pull requests are welcome! For development details, see the [contributing](https://github.com/infracost/infracost-atlantis/blob/master/CONTRIBUTING.md) guide. For major changes, including interface changes, please open an issue first to discuss what you would like to change. [Join our community Slack channel](https://www.infracost.io/community-chat), we are a friendly bunch and happy to help you get started :)

## License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
