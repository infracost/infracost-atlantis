# Terragrunt

This file contains working examples of how you can get Infracost and Terragrunt working together in your atlantis integration.

## Table of Contents

* [Running with GitHub](#running-with-github)
* [Running with GitLab](#running-with-gitlab)
* [Running with Azure Repos](#running-with-azure-repos)

## Running with GitHub

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image. You'll need to extend the image to include `terragrunt`. This can be done using something like the following:
   ```dockerfile
   FROM infracost/infracost-atlantis

   RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.0/terragrunt_linux_amd64 --output terragrunt && \
       chmod +x terragrunt && \
       mv terragrunt /usr/local/bin
   ```
2. You'll need to pass the following custom env vars into the container when running `infracost-atlantis`:
   ```sh
   GITHUB_TOKEN=<your-github-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files, altering it to fit your terragrunt project:
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
             # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
             # Use Infracost comment to create a comment containing the results for this project.
           - run: |
               infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                        --pull-request $PULL_NUM \
                                        --path $INFRACOST_OUTPUT \
                                        --github-token $GITHUB_TOKEN \
                                        --behavior new
   ```
4. Restart the Atlantis application with the new env vars and config.
5. Send a pull request in GitHub to change something in the Terraform code, the Infracost pull request comment should be added.

## Running with Gitlab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image. You'll need to extend the image to include `terragrunt`. This can be done using something like the following:
   ```dockerfile
   FROM infracost/infracost-atlantis

   RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.0/terragrunt_linux_amd64 --output terragrunt && \
       chmod +x terragrunt && \
       mv terragrunt /usr/local/bin
   ```
2. You'll need to pass the following custom env vars into the container:
   ```sh
   GITLAB_TOKEN=<your-gitlab-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files, altering it to fit your terragrunt project:
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
             # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
             # Use Infracost comment to create a comment containing the results for this project.
           - run: |
               infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                        --merge-request $PULL_NUM \
                                        --path $INFRACOST_OUTPUT \
                                        --gitlab-token $GITLAB_TOKEN \
                                        --behavior new
   ```
4. Restart the Atlantis application with the new env vars and config.
5. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment should be added.

## Running with Azure Repos

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image. You'll need to extend the image to include `terragrunt`. This can be done using something like the following:
   ```dockerfile
   FROM infracost/infracost-atlantis

   RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.0/terragrunt_linux_amd64 --output terragrunt && \
       chmod +x terragrunt && \
       mv terragrunt /usr/local/bin
   ```
2. You'll need to pass the following custom env vars into the container when running `infracost-atlantis`:
   ```sh
   AZURE_ACCESS_TOKEN=<your-azure-devops-access-token-or-pat>
   AZURE_REPO_URL=<your-azure-repo-url> # i.e., https://dev.azure.com/your-org/your-project/_git/your-repo
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following YAML spec to `repos.yaml` or `atlantis.yaml` config files, altering it to fit your terragrunt project:
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
               command: 'echo "/tmp/${BASE_REPO_OWNER//\//-}-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - env:
               name: TERRAGRUNT_TFPATH
               command: 'echo "terraform${ATLANTIS_TERRAFORM_VERSION}"'
           - run: terragrunt plan -out=$PLANFILE
           - run: terragrunt show -json $PLANFILE > $SHOWFILE
             # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: |
               infracost breakdown --path=$SHOWFILE \
                                   --format=json \
                                   --log-level=info \
                                   --out-file=$INFRACOST_OUTPUT
             # Use Infracost comment to create a comment containing the results for this project.
           - run: |
               infracost comment azure-repos --repo-url $AZURE_REPO_URL \
                                             --pull-request $PULL_NUM \
                                             --path $INFRACOST_OUTPUT \
                                             --azure-access-token $AZURE_ACCESS_TOKEN \
                                             --behavior new
   ```
4. Restart the Atlantis application with the new env vars and config.
5. Send a pull request in Azure Repos to change something in the Terraform code, the Infracost pull request comment should be added.
