# Multi-project

This `repo.yaml` file contains a workflow specification to use Infracost with a repository that contains multiple terraform projects. It uses `infracost comment` to post Infracost results to your PR.

## Table of Contents

* [Running with GitHub](#running-with-github)
* [Running with GitLab](#running-with-gitlab)
* [Running with Azure Repos](#running-with-azure-repos)

## Running with GitHub

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image.
2. You'll need to pass the following custom env vars into the container:
   ```sh
   GITHUB_TOKEN=<your-github-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:
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
               command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - env:
               name: INFRACOST_COMMENT_TAG
               command: 'echo "$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR"'
           - init
           - plan
           - show # this writes the plan JSON to $SHOWFILE
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
           - run: |
               # Use Infracost comment to create a comment containing the results for this project.
               #
               # Two things things to note of importance here:
               #
               # --behavior    defines the comment posting behavior of Infracost. We're using "new" here to post a comment on
               # every run of Atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
               # --tag     customises the embeded tag that Infracost uses to post a comment. We pass in the project DIR here
               # so that there are no conflicts across projects when posting to the PR. This is especially important if you
               # use a comment behavior like "update" or "delete-and-new".
               infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                        --pull-request $PULL_NUM \
                                        --path $INFRACOST_OUTPUT \
                                        --github-token $GITHUB_TOKEN \
                                        --tag $INFRACOST_COMMENT_TAG \
                                        --behavior new
 
   ```
4. Restart the Atlantis application with the new env vars and config.
5. Send a pull request in GitHub to change something in the Terraform code, the Infracost pull request comment should be added.

## Running with GitLab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image.
2. You'll need to pass the following custom env vars into the container:
   ```sh
   GITLAB_TOKEN=<your-gitlab-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:
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
               command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - env:
               name: INFRACOST_COMMENT_TAG
               command: 'echo "$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR"'
           - init
           - plan
           - show # this writes the plan JSON to $SHOWFILE
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
           - run: |
               # Use Infracost comment to create a comment containing the results for this project.
               #
               # Two things of importance to note here:
               #
               # --behavior    defines the comment posting behavior of Infracost. We're using "new" here to post a comment on
               # every run of Atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
               # --tag     customises the embeded tag that Infracost uses to post a comment. We pass in the project DIR here
               # so that there are no conflicts across projects when posting to the PR. This is especially important if you
               # use a comment behavior like "update" or "delete-and-new".
               infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                        --merge-request $PULL_NUM \
                                        --path $INFRACOST_OUTPUT \
                                        --gitlab-token $GITLAB_TOKEN \
                                        --tag $INFRACOST_COMMENT_TAG \
                                        --behavior new
   ```
4. Restart the Atlantis application with the new env vars and config
5. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment should be added.

## Running with Azure Repos

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image.
2. You'll need to pass the following custom env vars into the container:
   ```sh
   AZURE_ACCESS_TOKEN=<your-azure-devops-access-token-or-pat>
   AZURE_REPO_URL=<your-azure-repo-url> # i.e., https://dev.azure.com/your-org/your-project/_git/your-repo
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files:
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
               command: 'echo "/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - env:
               name: INFRACOST_COMMENT_TAG
               command: 'echo "${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR"'
           - init
           - plan
           - show # this writes the plan JSON to $SHOWFILE
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
           - run: |
               # Use Infracost comment to create a comment containing the results for this project.
               #
               # Two things of importance to note here:
               #
               # --behavior    defines the comment posting behavior of Infracost. We're using "new" here to post a comment on
               # every run of Atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
               # --tag     customises the embeded tag that Infracost uses to post a comment. We pass in the project DIR here
               # so that there are no conflicts across projects when posting to the PR. This is especially important if you
               # use a comment behavior like "update" or "delete-and-new".
               infracost comment azure-repos --repo-url $AZURE_REPO_URL \
                                             --pull-request $PULL_NUM \
                                             --path $INFRACOST_OUTPUT \
                                             --azure-access-token $AZURE_ACCESS_TOKEN \
                                             --tag $INFRACOST_COMMENT_TAG \
                                             --behavior new
   ```
4. Restart the Atlantis application with the new env vars and config
5. Send a pull request in Azure Repos to change something in the Terraform code, the Infracost pull request comment should be added.
