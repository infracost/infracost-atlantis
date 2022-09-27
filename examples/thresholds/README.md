# Thresholds

This example shows you how to run Infracost with Atlantis to post a comment on your PR when cloud costs exceed set thresholds.

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
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT \
                                  --project-name=$REPO_REL_DIR
          - run: |
              # Read the breakdown JSON and get costs using jq.
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base Atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              past=$(cat $INFRACOST_OUTPUT | jq -r "(.pastTotalMonthlyCost // 0) | tonumber")
              current=$(cat $INFRACOST_OUTPUT | jq -r "(.totalMonthlyCost // 0) | tonumber")
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")

              percent_change=999 # default to a high number so we post a comment if there's no past cost

              if [ "$past" != "0" ]; then
                percent_change=$(echo "100 * (($current - $past) / $past)" | bc -l)
              fi

              absolute_percent_change=$(echo "${percent_change#-}")

              echo "past: ${past}"
              echo "current: ${current}"
              echo "cost_change: ${cost_change}"
              echo "absolute_cost_change: ${cost_change#-}"
              echo "percent_change: ${percent_change}"
              echo "absolute_percent_change: ${absolute_percent_change}"

              if [ $(echo "absolute_percent_change < 10" | bc -l) == "1" ]; then  # Only comment if cost changed by more than plus or minus 10%
              # if [ $(echo "$percent_change < 10" | bc -l) == "1" ]; then        # Only comment if cost increased by more than 10%
              # if [ $(echo "$absolute_cost_change < 100" | bc -l) == "1" ]; then # Only comment if cost changed by more than plus or minus $100
              # if [ $(echo "$cost_change < 100" | bc -l) == "1" ]; then          # Only comment if cost increased by more than $100
                echo "Skipping comment, absolute percentage change is less than 10%"
                exit 0
              fi

              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --pull-request $PULL_NUM \
                                       --path $INFRACOST_OUTPUT \
                                       --github-token $GITHUB_TOKEN \
                                       --behavior new
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a pull request in GitHub to change something in Terraform code, the Infracost pull request comment will be added when you go above your set threshold.
8. [Enable Infracost Cloud](https://dashboard.infracost.io/) and trigger your CI/CD pipeline again. This causes the CLI to send its JSON output to your dashboard; the JSON does not contain any cloud credentials or secrets, see the [FAQ](https://infracost.io/docs/faq/) for more information. This is our SaaS product that builds on top of Infracost open source and enables team leads, managers and FinOps practitioners to see all cost estimates from a central place so they can help guide the team. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-dashboard.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners visibility across all cost estimates in CI/CD" width="90%" />

## Running with Gitlab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  GITLAB_TOKEN=<your-gitlab-token>
  INFRACOST_API_KEY=<your-infracost-api-token>
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
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT \
                                  --project-name=$REPO_REL_DIR
          - run: |
              # Read the breakdown JSON and get costs using jq.
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base Atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              past=$(cat $INFRACOST_OUTPUT | jq -r "(.pastTotalMonthlyCost // 0) | tonumber")
              current=$(cat $INFRACOST_OUTPUT | jq -r "(.totalMonthlyCost // 0) | tonumber")
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")

              percent_change=999 # default to a high number so we post a comment if there's no past cost

              if [ "$past" != "0" ]; then
                percent_change=$(echo "100 * (($current - $past) / $past)" | bc -l)
              fi

              absolute_percent_change=$(echo "${percent_change#-}")

              echo "past: ${past}"
              echo "current: ${current}"
              echo "cost_change: ${cost_change}"
              echo "absolute_cost_change: ${cost_change#-}"
              echo "percent_change: ${percent_change}"
              echo "absolute_percent_change: ${absolute_percent_change}"

              if [ $(echo "absolute_percent_change < 10" | bc -l) == "1" ]; then  # Only comment if cost changed by more than plus or minus 10%
              # if [ $(echo "$percent_change < 10" | bc -l) == "1" ]; then        # Only comment if cost increased by more than 10%
              # if [ $(echo "$absolute_cost_change < 100" | bc -l) == "1" ]; then # Only comment if cost changed by more than plus or minus $100
              # if [ $(echo "$cost_change < 100" | bc -l) == "1" ]; then          # Only comment if cost increased by more than $100
                echo "Skipping comment, absolute percentage change is less than 10%"
                exit 0
              fi

              infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --merge-request $PULL_NUM \
                                       --path $INFRACOST_OUTPUT \
                                       --gitlab-token $GITLAB_TOKEN \
                                       --behavior new
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment will be added when you go above your set threshold.
8. [Enable Infracost Cloud](https://dashboard.infracost.io/) and trigger your CI/CD pipeline again. This causes the CLI to send its JSON output to your dashboard; the JSON does not contain any cloud credentials or secrets, see the [FAQ](https://infracost.io/docs/faq/) for more information. This is our SaaS product that builds on top of Infracost open source and enables team leads, managers and FinOps practitioners to see all cost estimates from a central place so they can help guide the team. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-dashboard.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners visibility across all cost estimates in CI/CD" width="90%" />

## Running with Azure Repos

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  AZURE_ACCESS_TOKEN=<your-azure-devops-access-token-or-pat>
  AZURE_REPO_URL=<your-azure-repo-url> # i.e., https://dev.azure.com/your-org/your-project/_git/your-repo
  INFRACOST_API_KEY=<your-infracost-api-token>
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
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT \
                                  --project-name=$REPO_REL_DIR
          - run: |
              # Read the breakdown JSON and get costs using jq.
              # Note jq comes as standard as part of the infracost-atlantis Docker image. If you are using the base Atlantis
              # image you'll need to manually install jq. e.g:
              # curl https://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq; chmod +x /usr/local/bin/jq
              past=$(cat $INFRACOST_OUTPUT | jq -r "(.pastTotalMonthlyCost // 0) | tonumber")
              current=$(cat $INFRACOST_OUTPUT | jq -r "(.totalMonthlyCost // 0) | tonumber")
              cost_change=$(cat $INFRACOST_OUTPUT | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")

              percent_change=999 # default to a high number so we post a comment if there's no past cost

              if [ "$past" != "0" ]; then
                percent_change=$(echo "100 * (($current - $past) / $past)" | bc -l)
              fi

              absolute_percent_change=$(echo "${percent_change#-}")

              echo "past: ${past}"
              echo "current: ${current}"
              echo "cost_change: ${cost_change}"
              echo "absolute_cost_change: ${cost_change#-}"
              echo "percent_change: ${percent_change}"
              echo "absolute_percent_change: ${absolute_percent_change}"

              if [ $(echo "absolute_percent_change < 10" | bc -l) == "1" ]; then  # Only comment if cost changed by more than plus or minus 10%
              # if [ $(echo "$percent_change < 10" | bc -l) == "1" ]; then        # Only comment if cost increased by more than 10%
              # if [ $(echo "$absolute_cost_change < 100" | bc -l) == "1" ]; then # Only comment if cost changed by more than plus or minus $100
              # if [ $(echo "$cost_change < 100" | bc -l) == "1" ]; then          # Only comment if cost increased by more than $100
                echo "Skipping comment, absolute percentage change is less than 10%"
                exit 0
              fi

              infracost comment azure-repos --repo-url $AZURE_REPO_URL \
                                            --pull-request $PULL_NUM \
                                            --path $INFRACOST_OUTPUT \
                                            --azure-access-token $AZURE_ACCESS_TOKEN \
                                            --behavior new
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Send a pull request in Azure Repos to change something in Terraform code, the Infracost pull request comment will be added when you go above your set threshold.
8. [Enable Infracost Cloud](https://dashboard.infracost.io/) and trigger your CI/CD pipeline again. This causes the CLI to send its JSON output to your dashboard; the JSON does not contain any cloud credentials or secrets, see the [FAQ](https://infracost.io/docs/faq/) for more information. This is our SaaS product that builds on top of Infracost open source and enables team leads, managers and FinOps practitioners to see all cost estimates from a central place so they can help guide the team. To learn more, see [our docs](https://www.infracost.io/docs/infracost_cloud/get_started/).

    <img src="/.github/assets/infracost-cloud-dashboard.png" alt="Infracost Cloud gives team leads, managers and FinOps practitioners visibility across all cost estimates in CI/CD" width="90%" />
