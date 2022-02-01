This repo.yaml file contains a workflow specification to use Infracost with a repository that contains multiple terraform projects. It uses `infracost comment` to post a comment to your PR containing a combined Infracost cost estimate for all modified projects.

| Note: This examples requires Atlantis versions >= 18.2 due to the use of post_workflow_hooks |
| --- |

## Running with GitHub

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. You'll need to pass the following custom env vars into the container
   ```sh
   GITHUB_TOKEN=<your-github-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following yaml spec to `repos.yaml` config files:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
       pre_workflow_hooks:
         # Clean up any files left over from previous runs
         - run: rm -rf /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
         - run: mkdir -p /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
       post_workflow_hooks:         
         - run: |
              # Use Infracost comment to create a comment containing the results for this project.
              #
              # Two things things to note of importance here:
              #
              # --behavior    defines the comment posting behavior of infracost. We're using "new" here to post a comment on
              # every run of atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --pull-request $PULL_NUM \
                                       --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/'*'-infracost.json \
                                       --github-token $GITHUB_TOKEN \ 
                                       --behavior new
         - run: rm -rf /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
   workflows:
     terraform-infracost:
       plan:
         steps:
           - env:
               name: INFRACOST_OUTPUT
               command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=$INFRACOST_OUTPUT   
   ```
4. Restart the Atlantis application with the new env vars and config 
5. Send a pull request in GitHub to change something in the Terraform code, the Infracost pull request comment should be added and show details for every changed project.

## Running with GitLab

1. Update your setup to use the [infracost-atlantis](https://hub.docker.com/r/infracost/infracost-atlantis) Docker image
2. You'll need to pass the following custom env vars into the container
   ```sh
   GITLAB_TOKEN=<your-gitlab-token>
   INFRACOST_API_KEY=<your-infracost-api-token>
   ```
3. Add the following yaml spec to `repos.yaml` config files:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
       pre_workflow_hooks:
         # Clean up any files left over from previous runs
         - run: rm -rf /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
         - run: mkdir -p /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
       post_workflow_hooks:         
         - run: |
              # Use Infracost comment to create a comment containing the results for this project.
              #
              # Two things things to note of importance here:
              #
              # --behavior    defines the comment posting behavior of infracost. We're using "new" here to post a comment on
              # every run of atlantis for each project. There are also "update" & "delete-and-new" behaviors available.
              infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                                       --merge-request $PULL_NUM \
                                       --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/'*'-infracost.json \
                                       --gitlab-token $GITLAB_TOKEN \ 
                                       --behavior new
         - run: rm -rf /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM   
   workflows:
     terraform-infracost:
       plan:
         steps:
           - env:
               name: INFRACOST_OUTPUT
               command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-$REPO_REL_DIR-infracost.json"'
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=$INFRACOST_OUTPUT
   ```  
4. Restart the Atlantis application with the new env vars and config
5. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment should be added and show details for every changed project.
