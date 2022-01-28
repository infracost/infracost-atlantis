This example shows you how to run Infracost with Atlantis to post a comment on your PR when cloud costs exceed set thresholds.

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
               # Read the breakdown JSON and get costs
               past=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.pastTotalMonthlyCost // 0) | tonumber")
               current=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.totalMonthlyCost // 0) | tonumber")
               cost_change=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")

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
   
               if [ $(echo "$percent_change < 1" | bc -l) == "1" ]; then           # Only comment if cost changed by more than plus or minus 1%
               # if [ $(echo "$percent_change < 1" | bc -l) == "1" ]; then         # Only comment if cost increased by more than 1%
               # if [ $(echo "$absolute_cost_change < 100" | bc -l) == "1" ]; then # Only comment if cost changed by more than plus or minus $100
               # if [ $(echo "$cost_change < 100" | bc -l) == "1" ]; then          # Only comment if cost increased by more than $100
                 echo "Skipping comment, absolute percentage change is less than 1"
                 exit 0
               fi
   
               infracost comment github --repo $BASE_REPO_OWNER/$BASE_REPO_NAME --pull-request $PULL_NUM --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json --github-token $GITHUB_TOKEN
   ```
4. Restart the Atlantis application with the new env vars and config
5. Send a pull request in GitHub to change something in Terraform code, the Infracost pull request comment will be added when you go above your set threshold.

## Running with Gitlab

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
               # Read the breakdown JSON and get costs
               past=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.pastTotalMonthlyCost // 0) | tonumber")
               current=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.totalMonthlyCost // 0) | tonumber")
               cost_change=$(cat /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json | jq -r "(.diffTotalMonthlyCost // 0) | tonumber")

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
   
               if [ $(echo "$percent_change < 1" | bc -l) == "1" ]; then           # Only comment if cost changed by more than plus or minus 1%
               # if [ $(echo "$percent_change < 1" | bc -l) == "1" ]; then         # Only comment if cost increased by more than 1%
               # if [ $(echo "$absolute_cost_change < 100" | bc -l) == "1" ]; then # Only comment if cost changed by more than plus or minus $100
               # if [ $(echo "$cost_change < 100" | bc -l) == "1" ]; then          # Only comment if cost increased by more than $100
                 echo "Skipping comment, absolute percentage change is less than 1"
                 exit 0
               fi
   
               infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME --merge-request $PULL_NUM --path /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-$REPO_REL_DIR-infracost.json --gitlab-token $GITLAB_TOKEN
   ```
4. Restart the Atlantis application with the new env vars and config
5. Send a merge request in GitLab to change something in the Terraform code, the Infracost merge request comment will be added when you go above your set threshold.
