# Slack example

This `repo.yaml` file contains a workflow specification to send Infracost cost estimates to Slack.

Slack message blocks have a 3000 char limit so the Infracost CLI automatically truncates the middle of `slack-message` output format.

## Table of Contents

* [Running with GitHub](#running-with-github)
* [Running with GitLab](#running-with-gitlab)
* [Running with Azure Repos](#running-with-azure-repos)

For Bitbucket, see [our docs](https://www.infracost.io/docs/features/cli_commands/#bitbucket) for how to post comments using `infracost comment bitbucket`.

## Running with GitHub

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  GITHUB_TOKEN=<your-github-token>
  INFRACOST_API_KEY=<your-infracost-api-token>
  SLACK_WEBHOOK_URL: <your-slack-webhook-url>
  ```

5. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - env:
              name: INFRACOST_SLACK_MESSAGE
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-slack-message.json"'
          # This instructs the CLI to send cost estimates to Infracost Cloud. Our SaaS product
          #   complements the open source CLI by giving teams advanced visibility and controls.
          #   The cost estimates are transmitted in JSON format and do not contain any cloud
          #   credentials or secrets (see https://infracost.io/docs/faq/ for more information).
          - env:
              name: INFRACOST_ENABLE_CLOUD
              value: true
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT
                                  --project-name=$REPO_REL_DIR
          # Use Infracost comment to create a comment containing the results for this project
          - run: |
              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --pull-request $PULL_NUM \
                                       --path $INFRACOST_OUTPUT \
                                       --github-token $GITHUB_TOKEN \
                                       --behavior new
          # Use Infracost output command to create a message payload for Slack
          - run: |
              infracost output --path $INFRACOST_OUTPUT \
                              --format slack-message \
                              --out-file $INFRACOST_SLACK_MESSAGE
          # Use cURL to send a Slack message via a webhook
          - run: |
              # Skip posting to Slack if there's no cost change
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")
              if [ "$cost_change" = "0" ]; then
                echo "Not posting to Slack since cost change is zero"
                exit 0
              fi

              if [ -z "$SLACK_WEBHOOK_URL" ]; then
                echo "No \$SLACK_WEBHOOK_URL variable set."
                exit 1
              fi

              curl -X POST -H "Content-type: application/json" -d @$INFRACOST_SLACK_MESSAGE $SLACK_WEBHOOK_URL
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a pull request in GitHub to change something in the Terraform code, the Infracost pull request comment will be added and a Slack message will be posted if there is cost change.
8. To see the test pull request costs in Infracost Cloud, [log in](https://dashboard.infracost.io/) > switch to your organization > Projects. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-runs.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners to have visibility across all cost estimates in CI/CD" width="90%" />
9. Follow [the docs](https://www.infracost.io/usage-file) if you'd also like to show cost for of usage-based resources such as AWS Lambda or S3. The usage for these resources are fetched from CloudWatch/cloud APIs and used to calculate an estimate.

## Running with GitLab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  GITLAB_TOKEN=<your-gitlab-token>
  INFRACOST_API_KEY=<your-infracost-api-token>
  SLACK_WEBHOOK_URL: <your-slack-webhook-url>
  ```

5. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - env:
              name: INFRACOST_SLACK_MESSAGE
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-slack-message.json"'
          # This instructs the CLI to send cost estimates to Infracost Cloud. Our SaaS product
          #   complements the open source CLI by giving teams advanced visibility and controls.
          #   The cost estimates are transmitted in JSON format and do not contain any cloud
          #   credentials or secrets (see https://infracost.io/docs/faq/ for more information).
          - env:
              name: INFRACOST_ENABLE_CLOUD
              value: true
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT
                                  --project-name=$REPO_REL_DIR
          # Use Infracost comment to create a comment containing the results for this project
          - run: |
              infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --merge-request $PULL_NUM \
                                       --path $INFRACOST_OUTPUT \
                                       --gitlab-token $GITLAB_TOKEN \
                                       --behavior new
          # Use Infracost output command to create a message payload for Slack
          - run: |
              infracost output --path $INFRACOST_OUTPUT \
                              --format slack-message \
                              --out-file $INFRACOST_SLACK_MESSAGE
          # Use cURL to send a Slack message via a webhook
          - run: |
              # Skip posting to Slack if there's no cost change
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")
              if [ "$cost_change" = "0" ]; then
                echo "Not posting to Slack since cost change is zero"
                exit 0
              fi

              if [ -z "$SLACK_WEBHOOK_URL" ]; then
                echo "No \$SLACK_WEBHOOK_URL variable set."
                exit 1
              fi

              curl -X POST -H "Content-type: application/json" -d @$INFRACOST_SLACK_MESSAGE $SLACK_WEBHOOK_URL
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment will be added and a Slack message will be posted if there is cost change.
8. To see the test pull request costs in Infracost Cloud, [log in](https://dashboard.infracost.io/) > switch to your organization > Projects. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-runs.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners to have visibility across all cost estimates in CI/CD" width="90%" />
9. Follow [the docs](https://www.infracost.io/usage-file) if you'd also like to show cost for of usage-based resources such as AWS Lambda or S3. The usage for these resources are fetched from CloudWatch/cloud APIs and used to calculate an estimate.

## Running with Azure Repos

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  AZURE_ACCESS_TOKEN=<your-azure-devops-access-token-or-pat>
  AZURE_REPO_URL=<your-azure-repo-url> # i.e., https://dev.azure.com/your-org/your-project/_git/your-repo
  INFRACOST_API_KEY=<your-infracost-api-token>
  SLACK_WEBHOOK_URL: <your-slack-webhook-url>
  ```

5. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - env:
              name: INFRACOST_SLACK_MESSAGE
              command: 'echo "/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-slack-message.json"'
          # This instructs the CLI to send cost estimates to Infracost Cloud. Our SaaS product
          #   complements the open source CLI by giving teams advanced visibility and controls.
          #   The cost estimates are transmitted in JSON format and do not contain any cloud
          #   credentials or secrets (see https://infracost.io/docs/faq/ for more information).
          - env:
              name: INFRACOST_ENABLE_CLOUD
              value: true
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT
                                  --project-name=$REPO_REL_DIR
          # Use Infracost comment to create a comment containing the results for this project
          - run: |
              infracost comment azure-repos --repo-url $AZURE_REPO_URL \
                                            --pull-request $PULL_NUM \
                                            --path $INFRACOST_OUTPUT \
                                            --azure-access-token $AZURE_ACCESS_TOKEN \
                                            --behavior new
          # Use Infracost output command to create a message payload for Slack
          - run: |
              infracost output --path $INFRACOST_OUTPUT \
                              --format slack-message \
                              --out-file $INFRACOST_SLACK_MESSAGE
          # Use cURL to send a Slack message via a webhook
          - run: |
              # Skip posting to Slack if there's no cost change
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")
              if [ "$cost_change" = "0" ]; then
                echo "Not posting to Slack since cost change is zero"
                exit 0
              fi

              if [ -z "$SLACK_WEBHOOK_URL" ]; then
                echo "No \$SLACK_WEBHOOK_URL variable set."
                exit 1
              fi

              curl -X POST -H "Content-type: application/json" -d @$INFRACOST_SLACK_MESSAGE $SLACK_WEBHOOK_URL
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a pull request in Azure Repos to change something in the Terraform code, the Infracost pull request comment will be added and a Slack message will be posted if there is cost change.
8. To see the test pull request costs in Infracost Cloud, [log in](https://dashboard.infracost.io/) > switch to your organization > Projects. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-runs.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners to have visibility across all cost estimates in CI/CD" width="90%" />
9. Follow [the docs](https://www.infracost.io/usage-file) if you'd also like to show cost for of usage-based resources such as AWS Lambda or S3. The usage for these resources are fetched from CloudWatch/cloud APIs and used to calculate an estimate.
