# Infracost comment

This Atlantis repo.yaml file shows how Infracost can be used with Atlantis. Even when a repository that contains multiple terraform directories or workspaces is used, this example uses `infracost comment` to post a combined cost estimate comment for all modified projects.

<img src="screenshot.png" width=640 alt="Example screenshot" />

## Table of Contents

* [Running with GitHub](#running-with-github)
* [Running with GitLab](#running-with-gitlab)
* [Running with Azure Repos](#running-with-azure-repos)
* [Running with Bitbucket](#running-with-bitbucket)

## Running with GitHub

👉👉 We recommend using the [**free Infracost GitHub App**](https://www.infracost.io/docs/integrations/github_app/) as it's much simpler to setup and faster to run

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env var into the container.

  ```sh
  GITHUB_TOKEN=<your-github-token>
  INFRACOST_API_KEY=<your-infracost-api-token>
  ```

5. Add the following yaml spec to `repos.yaml` or `atlantis.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
      pre_workflow_hooks:
        # Clean up any files left over from previous runs
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
            rm -rf $INFRACOST_DIR && \
            mkdir -p $INFRACOST_DIR
          commands: plan
      post_workflow_hooks:
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM  
            if [ "$(ls -A $INFRACOST_DIR)" ]; then
              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                     --pull-request $PULL_NUM \
                                     --path $INFRACOST_DIR/'*'-infracost.json \
                                     --github-token $GITHUB_TOKEN \
                                     --behavior new
            else
              echo "Infracost comment not posted because $INFRACOST_DIR is empty."
            fi
          commands: plan
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: |
              export INFRACOST_VCS_PULL_REQUEST_TITLE=\"$(curl -s \
                  -H "Accept: application/vnd.github+json" \
                  -H "Authorization: Bearer $GITHUB_TOKEN" \
                  "https://api.github.com/repos/$BASE_REPO_OWNER/$BASE_REPO_NAME/pulls/$PULL_NUM" | jq -r '.title')\"
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --log-level=info \
                                  --out-file=$INFRACOST_OUTPUT \
                                  --project-name=$REPO_REL_DIR
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Continue with the setup steps [here](../../?tab=readme-ov-file#3-test-the-integration).

## Running with GitLab

👉👉 We recommend using the [**free Infracost GitLab App**](https://www.infracost.io/docs/integrations/gitlab_app/) as it's much simpler to setup and faster to run

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env var into the container.

  ```sh
  GITLAB_TOKEN=<your-gitlab-token>
  INFRACOST_API_KEY=<your-infracost-api-token>
  ```

5. Add the following yaml spec to `repos.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
      pre_workflow_hooks:
        # Clean up any files left over from previous runs
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
            rm -rf $INFRACOST_DIR && \
            mkdir -p $INFRACOST_DIR
          command: plan
      post_workflow_hooks:
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
            if [ "$(ls -A $INFRACOST_DIR)" ]; then
              infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                          --merge-request $PULL_NUM \
                                          --path $INFRACOST_DIR/'*'-infracost.json \
                                          --gitlab-token $GITLAB_TOKEN \
                                          --behavior new
            else
              echo "Infracost comment not posted because $INFRACOST_DIR is empty."
            fi
          command: plan
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: infracost breakdown --path=$SHOWFILE --format=json --log-level=info --out-file=$INFRACOST_OUTPUT --project-name=$REPO_REL_DIR
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Continue with the setup steps [here](../../?tab=readme-ov-file#3-test-the-integration).

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

3. Add the following yaml spec to `repos.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
      pre_workflow_hooks:
        # Clean up any files left over from previous runs
        - run: | 
            INFRACOST_DIR=/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM
            rm -rf $INFRACOST_DIR && \
            mkdir -p $INFRACOST_DIR
          command: plan
      post_workflow_hooks:
        - run: |
            INFRACOST_DIR=/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM
            if [ "$(ls -A $INFRACOST_DIR)" ]; then
              infracost comment azure-repos --repo-url $AZURE_REPO_URL \
                                          --pull-request $PULL_NUM \
                                          --path $INFRACOST_DIR/'*'-infracost.json \
                                          --azure-access-token $AZURE_ACCESS_TOKEN \
                                          --tag $INFRACOST_COMMENT_TAG \
                                          --behavior new
            else
              echo "Infracost comment not posted because $INFRACOST_DIR is empty."
            fi
          command: plan
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - init
          - plan
          - show # this writes the plan JSON to $SHOWFILE
          # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
          - run: infracost breakdown --path=$SHOWFILE --format=json --log-level=info --out-file=$INFRACOST_OUTPUT --project-name=$REPO_REL_DIR
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Continue with the setup steps [here](../../?tab=readme-ov-file#3-test-the-integration).

## Running with Bitbucket

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. If you haven't done so already, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.
3. Retrieve your Infracost API key by running `infracost configure get api_key`.
4. You'll need to pass the following custom env vars into the container. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost auth login` to get a free API key.

  ```sh
  BITBUCKET_TOKEN=<your-bitbucket-token> # for Bitbucket Cloud this should be username:token, where the token can be a user or App password. For Bitbucket Server provide only an HTTP access token.
  INFRACOST_API_KEY=<your-infracost-api-token>
  ```

5. Add the following yaml spec to `repos.yaml` config files:

  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
      pre_workflow_hooks:
        # Clean up any files left over from previous runs
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
            rm -rf $INFRACOST_DIR && \
            mkdir -p $INFRACOST_DIR
          commands: plan
      post_workflow_hooks:
        - run: |
            INFRACOST_DIR=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
            if [ "$(ls -A $INFRACOST_DIR)" ]; then
              infracost comment bitbucket --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                        --pull-request $PULL_NUM \
                                        --path $INFRACOST_DIR/'*'-infracost.json \
                                        --bitbucket-token $BITBUCKET_TOKEN \
                                        --behavior new
            else
              echo "Infracost comment not posted because $INFRACOST_DIR is empty."
            fi
          commands: plan
  workflows:
    terraform-infracost:
      plan:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
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
  ```

6. Restart the Atlantis application with the new environment vars and config.
7. Continue with the setup steps [here](../../?tab=readme-ov-file#3-test-the-integration).
