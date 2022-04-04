# Infracost Atlantis Integration

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis, so you can see cloud cost estimates for Terraform in pull requests 💰

<img src="examples/combined-infracost-comment/screenshot.png" width=640 alt="Example screenshot" />

Follow our [migration guide](https://www.infracost.io/docs/guides/atlantis_migration/) if you used our old version of this repo.

## Usage methods

Since Atlantis does not have a plugins concept, you need to make **two** decisions to integrate it with Infracost:

### 1. Which deployment option do you want to use?

#### a) Use our Docker images (recommended)
Use our [`infracost-atlantis`](https://hub.docker.com/r/infracost/infracost-atlantis) Docker images that [extend](https://www.runatlantis.io/docs/deployment.html#customization) the Atlantis image to add Infracost. We maintain tags for the latest two 0.x versions of Atlantis:
  - `infracost/infracost-atlantis:atlantis0.18-infracost0.9` latest patch version of Atlantis v0.18 and Infracost v0.9
  - `infracost/infracost-atlantis:atlantis0.17-infracost0.9` latest patch version of Atlantis v0.17 and Infracost v0.9
  - `infracost/infracost-atlantis:latest` latest versions of Atlantis and Infracost

#### b) Build your own Docker image
If you already use a custom Docker image for Atlantis, copy the top `RUN` command from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

#### c) Install in pre-workflow (good for testing)
Use Atlantis `pre_workflow_hooks` to dynamically install the Infracost CLI on a running Atlantis server (shown in the following repos.yml example). This enables you to test Infracost without changing your Docker image by installing it on each workflow run. Once you're happy with the results, you can use one of the above methods.

To use this method, add the following pre_workflow_hook to your chosen option in the next step. Environment variables such as `INFRACOST_API_KEY` also need to be passed into the Atlantis container.

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

### 2. How do you want multiple Terraform directories/workspaces to be handled?

This option depends on what version of Atlantis you have and how you'd like to handle cost estimates for multiple Terraform directories/workspaces. The following table explains the options and links to instructions as well as screenshots.

<table>
  <thead>
    <tr>
        <th></th>
        <th>If you're using Atlantis 0.18.2 or newer</th>
        <th>If you're using older than Atlantis 0.18.2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>a) Recommended:</b> combine cost estimates from multiple Terraform directories/workspaces into one Infracost pull request comment. Enables you to see the total cost estimate in one table.</td>
      <td><a href="examples/combined-infracost-comment/README.md">Use this option</a></td>
      <td>Not possible since post_workflow_hooks were added in Atlantis 0.18.2</td>
    </tr>
    <tr>
      <td><b>b)</b> Post one Infracost pull request comment per Terraform directory/workspace. This is the best option for users who cannot upgrade Atlantis yet.</td>
      <td colspan=2 align=center><a href="examples/multiple-infracost-comments/README.md">Use this option</a></td>
    </tr>
    <tr>
      <td><b>c)</b> Append cost estimates to the bottom of Atlantis' "Show output" section of the pull request comment. Similar to option b) but the cost estimate is somewhat hidden. This is how our legacy integration worked but most users we talked to wanted option a).</td>
      <td colspan=2 align=center><a href="examples/append-to-atlantis-comments/README.md">Use this option</a></td>
    </tr>
  </tbody>
</table>

## Additional examples

The following examples might be helpful to use alongside the above examples:
- [Slack](./examples/slack/README.md): post cost estimates to Slack
- [Conftest](./examples/conftest/README.md): check cost policies using Atlantis' native Conftest integration and Infracost cost estimates.

If you do not use Conftest/Open Policy Agent, you can still set [thresholds](./examples/thresholds/README.md) using bash and [jq](https://stedolan.github.io/jq/) so notifications or pull request comments are only sent when cost thresholds are exceeded.

## Atlantis usage notes

### Private Terraform modules

To use with Terraform modules that are hosted in a private git repository you can add the `--write-git-creds` flag to your `atlantis server` command.

### Terraform Cloud/Enterprise

To use with Terraform Cloud/Enterprise you can add the following flags to your `atlantis server` command: `--tfe-hostname='MY_TFE_HOSTNAME' --tfe-token='MY_TFE_TOKEN'`.

### Terragrunt

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
                command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
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
