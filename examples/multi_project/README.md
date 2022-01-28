This repo.yaml file contains a workflow specification to use Infracost with a repository that contains multiple terraform projects. It uses `infracost comment` to post Infracost results to your PR. 

## Running with GitHub

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. You'll need to pass the following custom env vars into the container
   ```sh
   GITHUB_TOKEN=<your-github-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following yaml spec to `repos.yaml` or `atlantis.yaml` config files:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
   workflows:
     terraform-infracost:
       plan:
         steps:
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
           - run: |
              # Use Infracost comment to create a comment containing the results for this project.
              #
              # Two things things to note of importance here:
              #
              # --behavior    defines the comment posting behavior of infracost. We're using "new" here to post a comment on
              # every run of atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
              # --tag     customises the embeded tag that Infracost uses to post a comment. We pass in the project DIR here
              # so that there are no confilcts across projects when posting to the PR. This is especially important if you 
              # use a comment behavior like "update" or "delete-and-new".
              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --pull-request $PULL_NUM \
                                       --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json \
                                       --github-token $GITHUB_TOKEN \ 
                                       --tag $BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR \
                                       --behavior new 
   
   ```
4. Restart the Atlantis application with the new env vars and config 
5. Send a pull request in GitHub to change something in the Terraform code, the Infracost pull request comment should be added.

## Running with GitLab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. You'll need to pass the following custom env vars into the container
   ```sh
   GITLAB_TOKEN=<your-gitlab-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following yaml spec to `repos.yaml` or `atlantis.yaml` config files:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
   workflows:
     terraform-infracost:
       plan:
         steps:
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
           - run: |
              # Use Infracost comment to create a comment containing the results for this project.
              #
              # Two things of importance to note here:
              #
              # --behavior    defines the comment posting behavior of infracost. We're using "new" here to post a comment on
              # every run of atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
              # --tag     customises the embeded tag that Infracost uses to post a comment. We pass in the project DIR here
              # so that there are no confilcts across projects when posting to the PR. This is especially important if you 
              # use a comment behavior like "update" or "delete-and-new".
              infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --merge-request $PULL_NUM \
                                       --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json \
                                       --gitlab-token $GITLAB_TOKEN \ 
                                       --tag $BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR \
                                       --behavior new 
   ```  
4. Restart the Atlantis application with the new env vars and config
5. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment should be added.
