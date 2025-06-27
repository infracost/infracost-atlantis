# Infracost Atlantis Integration

### Try the GitHub, GitLab or Azure Repos App
👉👉 If you use Atlantis with GitHub/GitLab/Azure Repos, we recommend using the free Infracost [**GitHub App**](https://www.infracost.io/docs/integrations/github_app/), [**GitLab App**](https://www.infracost.io/docs/integrations/gitlab_app/) or [**Azure Repos App**](https://www.infracost.io/docs/integrations/azure_repos_app/) as they're much simpler to setup and faster to run

---

This repo shows how [Infracost](https://infracost.io) can be used with Atlantis, so you can see cloud cost estimates and FinOps best practices for Terraform in pull requests 💰

<img src="examples/infracost-comment/screenshot.png" width=640 alt="Example screenshot" />

## Usage

### 1. Decide deployment option

Since Atlantis does not have a plugins concept, you need to decide which deployment option to use:

#### a. Use our Docker images (recommended)
Use our [`infracost-atlantis`](https://hub.docker.com/r/infracost/infracost-atlantis) Docker images that [extend](https://www.runatlantis.io/docs/deployment.html#customization) the Atlantis image to add Infracost. We maintain tags for the latest two 0.x versions of Atlantis:
  - `infracost/infracost-atlantis:atlantis0.34-infracost0.10` latest patch version of Atlantis v0.35 and Infracost v0.10
  - `infracost/infracost-atlantis:atlantis0.33-infracost0.10` latest patch version of Atlantis v0.34 and Infracost v0.10
  - `infracost/infracost-atlantis:latest` latest versions of Atlantis and Infracost

#### b. Build your own Docker image
If you already use a custom Docker image for Atlantis, copy the top `RUN` command from [this Dockerfile](https://github.com/infracost/infracost-atlantis/blob/master/Dockerfile) into your Dockerfile.

#### c. Install in pre-workflow (good for testing)
Use Atlantis `pre_workflow_hooks` to dynamically install the Infracost CLI on a running Atlantis server (shown in the following repos.yml example). This enables you to test Infracost without changing your Docker image by installing it on each workflow run. Once you're happy with the results, you can use one of the above methods.

To use this method, add the following `pre_workflow_hook` to your chosen option in the next step. Also change references to the Infracost CLI invocation to `/tmp/infracost` in the the next step. [Environment variables](https://www.infracost.io/docs/integrations/environment_variables/) such as `INFRACOST_API_KEY` also need to be passed into the Atlantis container.

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
      pre_workflow_hooks:
        # Install Infracost, use `/tmp/infracost` to run the CLI in step 2
        - run: |
            /tmp/infracost --version && [ $(/tmp/infracost --version 2>&1 | grep -c "A new version of Infracost is available") = 0 ] || \
              curl -L https://infracost.io/downloads/v0.10/infracost-linux-amd64.tar.gz --output infracost.tar.gz && \
              tar -xvf infracost.tar.gz && \
              mv infracost-linux-amd64 /tmp/infracost
  ```

### 2. Setup Infracost

Once you've decided, **<a href="examples/infracost-comment/README.md">follow this guide</a>** to setup Infracost with Atlantis.

### 3. Test the integration

Follow [these simple steps](https://www.infracost.io/docs/infracost_cloud/get_started/#4-send-a-pull-request) to test the integration. This is important as it ensures the CLI commands are running correctly in your workflow 👌

- [Infracost Cloud](https://dashboard.infracost.io) is our SaaS product that builds on top of Infracost open source. It enables team leads, managers and FinOps practitioners to setup [tagging policies](https://www.infracost.io/docs/infracost_cloud/tagging_policies/), [guardrails](https://www.infracost.io/docs/infracost_cloud/guardrails/) and [best practices](https://www.infracost.io/docs/infracost_cloud/cost_policies/) to help guide the team. For example, you can check for required tag keys/values, or suggest switching AWS gp2 volumes to gp3 as they are more performant and cheaper.

    If you **do not** want to use [Infracost Cloud](https://dashboard.infracost.io), go to Org Settings and disable the dashboard. This causes the CLI not to send its JSON output to your dashboard; the JSON does not contain any cloud credentials or secrets, see the [FAQ](https://infracost.io/docs/faq/) for more information.

    <img src=".github/assets/infracost-cloud-dashboard.png" alt="Infracost Cloud enables you to check for best practices such as using latest generation instance types or block storage, as well as setup tagging policies and guardrails to help guide the team." />

## Atlantis usage notes

### Private Terraform modules

To use with Terraform modules that are hosted in a private git repository you can add the `--write-git-creds` flag to your `atlantis server` command.

### Project names

Project names default to the relative path of the project using the Atlantis `$REPO_REL_DIR` environment variable. See [our docs](https://www.infracost.io/docs/infracost_cloud/key_concepts/#customize-project-names) to customize this.

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
                command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
            - env:
                name: TERRAGRUNT_TFPATH
                command: 'echo "terraform${ATLANTIS_TERRAFORM_VERSION}"'
            - run: terragrunt plan -out=$PLANFILE
            - run: terragrunt show -json $PLANFILE > $SHOWFILE
            # Add custom steps here from the examples mentioned elsewhere in this readme
    ```

### Overriding metadata

If you use [Infracost Cloud](https://dashboard.infracost.io), you might need to [override metadata](https://www.infracost.io/docs/features/environment_variables/#environment-variables-to-set-metadata) such as the pull request author or title that is shown on the Infracost Cloud dashboard.

```bash
INFRACOST_VCS_PROVIDER="github" # For GitHub Enterprise, also use "github"
INFRACOST_VCS_REPOSITORY_URL="https://github.com/$BASE_REPO_OWNER/$BASE_REPO_NAME"
INFRACOST_VCS_PULL_REQUEST_URL="$INFRACOST_VCS_REPOSITORY_URL/pulls/$PULL_NUM"
INFRACOST_VCS_PULL_REQUEST_AUTHOR="$PULL_AUTHOR"
INFRACOST_VCS_BASE_BRANCH="$BASE_BRANCH_NAME"

INFRACOST_VCS_PULL_REQUEST_TITLE=\"$(curl -s \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: $GITHUB_TOKEN" \
    "https://api.github.com/repos/$BASE_REPO_OWNER/$BASE_REPO_NAME/pulls/$PULL_NUM" | jq -r '.title')\"
```

## Contributing

Issues and pull requests are welcome! For development details, see the [contributing](https://github.com/infracost/infracost-atlantis/blob/master/CONTRIBUTING.md) guide. For major changes, including interface changes, please open an issue first to discuss what you would like to change. [Join our community Slack channel](https://www.infracost.io/community-chat), we are a friendly bunch and happy to help you get started :)

## License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
