This repo.yaml file contains a workflow specification to use Infracost with a single project. It uses `infracost comment` to post Infracost results to your PR. 

## Running with GitHub

1. On the Atlantis server, export env vars for:
   ```sh
   export GITHUB_TOKEN=<your-github-token>
   export INFRACOST_API_KEY=<your-infracost-api-token>
   ```
2. Add the following yaml to `repos.yaml` or `atlantis.yaml` server side config file:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
       pre_workflow_hooks:
         # Clean up any files left over from the last run
         - run: rm /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
   workflows:
     terraform-infracost:
       plan:
         steps:
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
           # Use Infracost comment to create a comment containing the results for this project.
           - run: infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME --pull-request $PULL_NUM --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json --github-token $GITHUB_TOKEN
   ```
3. Run the `infracost/infracost-atlantis` image, which includes the Infracost CLI in addition to Atlantis:
   ```sh
      docker run -p 4141:4141 -e GITHUB_TOKEN=$GITHUB_TOKEN -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
        --mount type=bind,source=<path-to-local-yml-file>,target=/home/atlantis/repo.yml \
        infracost/infracost-atlantis:latest \
        --gh-user=<your-github-user> \
        --gh-token=$GITHUB_TOKEN \
        --gh-webhook-secret=<your-github-webhook-secret> \
        --repo-allowlist='github.com/your-org/*' \
        --repo-config=/home/atlantis/repo.yml
   ```
4. Send a pull request in GitHub to change something in TF, the Infracost pull request comment should be added.

## Running with Gitlab

1. On the Atlantis server, export env vars for:
   ```sh
   export GITLAB_TOKEN=<your-gitlab-token>
   export INFRACOST_API_KEY=<your-infracost-api-token>
   ```
2. Add the following yaml to `repos.yaml` or `atlantis.yaml` server side config file:
   ```yaml
   repos:
     - id: /.*/
       workflow: terraform-infracost
       pre_workflow_hooks:
         # Clean up any files left over from the last run
         - run: rm /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
   workflows:
     terraform-infracost:
       plan:
         steps:
           - init
           - plan
           # Run Infracost breakdown and save to a tempfile, namespaced by this project, PR, workspace and dir
           - run: infracost breakdown --path=$PLANFILE --format=json --log-level=info --out-file=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json
           # Use Infracost comment to create a comment containing the results for this project.
           - run: infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME --merge-request $PULL_NUM --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json --gitlab-token $GITLAB_TOKEN
   ```  
3. Run the `infracost/infracost-atlantis` image, which includes the Infracost CLI in addition to Atlantis:
   ```sh
   docker run -p 4141:4141 -e GITLAB_TOKEN=$GITLAB_TOKEN -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
     --mount type=bind,source=<path-to-local-yml-file>,target=/home/atlantis/repo.yml \
     infracost/infracost-atlantis:latest \
     --gitlab-user=<your-gitlab-user> \
     --gitlab-token=$GITLAB_TOKEN \
     --gitlab-webhook-secret=<your-gitlab-webhook-secret> \
     --repo-allowlist='gitlab.com/your-org/*' \
     --repo-config=/home/atlantis/repo.yml
   ```
4. Send a merge request in GitLab to change something in TF, the Infracost merge request comment should be added.
