# Conftest Example

This example shows how to use [Atlantis' built-in Conftest](https://www.runatlantis.io/docs/policy-checking.html) support with Infracost to enforce cost policies.

## Table of Contents

* [Configuration](#configuration)
* [Running with GitHub](#running-with-github)
* [Running with GitLab](#running-with-gitlab)
* [Running with Azure Repos](#running-with-azure-repos)
* [Usage](#usage)

## Configuration

1. Add the YAML contents of this file to your `repos.yaml` or `atlantis.yaml` server side config file:
  ```yaml
  repos:
    - id: /.*/
      workflow: terraform-infracost
  workflows:
    terraform-infracost:
      policy_check:
        steps:
          - env:
              name: INFRACOST_OUTPUT
              command: 'echo "/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM-$WORKSPACE-${REPO_REL_DIR//\//-}-infracost.json"'
          - show # this writes the plan JSON to $SHOWFILE
          - run: echo "Generating Infracost cost estimates for ${REPO_REL_DIR//\//-}/$WORKSPACE..."
          - run: |
              infracost breakdown --path=$SHOWFILE \
                                  --format=json \
                                  --out-file=$INFRACOST_OUTPUT \
                                  --log-level=warn \
                                  --no-color
          - policy_check:
              extra_args: [ "-p /home/atlantis/policy", "--namespace", "infracost", "$INFRACOST_OUTPUT" ]
  policies:
    owners:
      users:
        - example-dev
    policy_sets:
      - name: infracost-tests
        path: /home/atlantis/policy
        source: local
  ```
2. Create a policy file in the [Rego language](https://www.openpolicyagent.org/docs/latest/policy-language/) `policy.rego` and make it available at `/home/atlantis/policy`:
  ```rego
  package infracost

  deny_totalDiff[msg] {
  maxDiff = 1500.0
  to_number(input.diffTotalMonthlyCost) >= maxDiff

          msg := sprintf(
              "Total monthly cost diff must be < $%.2f (actual diff is $%v)",
              [maxDiff, to_number(input.diffTotalMonthlyCost)],
          )
  }

  deny_instanceCost[msg] {
  r := input.projects[_].breakdown.resources[_]
  startswith(r.name, "aws_instance.")

          maxHourlyCost := 2.0
          to_number(r.hourlyCost) > maxHourlyCost

          msg := sprintf(
              "AWS instances must cost less than $%.2f\\hr (%s costs $%v\\hr).",
              [maxHourlyCost, r.name, to_number(r.hourlyCost)],
          )
  }

  deny_instanceCost[msg] {
  r := input.projects[_].breakdown.resources[_]
  startswith(r.name, "aws_instance.")

          baseHourlyCost := to_number(r.costComponents[_].hourlyCost)

          sr_cc := r.subresources[_].costComponents[_]
          sr_cc.name == "Provisioned IOPS"
          iopsHourlyCost := to_number(sr_cc.hourlyCost)

          iopsHourlyCost > baseHourlyCost

          msg := sprintf(
              "AWS instance IOPS must cost less than compute usage (%s IOPS $%v\\hr, usage $%v\\hr).",
              [r.name, iopsHourlyCost, baseHourlyCost],
          )
  }
  ```
3. On the Atlantis server, export env vars for the following. Retrieve your Infracost API key by running `infracost configure get api_key`. We recommend using your same API key in all environments. If you don't have one, [download Infracost](https://www.infracost.io/docs/#quick-start) and run `infracost register` to get a free API key.
  ```
  export INFRACOST_API_KEY=<your-infracost-api-token>
  ```

## Running with GitHub

1. Run the `infracost/infracost-atlantis` image, which includes the Infracost CLI in addition to Atlantis:
  ```
  docker run -p 4141:4141 -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
    --mount type=bind,source=$(pwd)/examples/conftest/conftest.yml,target=/home/atlantis/repo.yml \
    --mount type=bind,source=$(pwd)/examples/conftest/policy,target=/home/atlantis/policy \
    infracost/infracost-atlantis:latest \
    --gh-user=<your-github-user> \
    --gh-token=$GITHUB_TOKEN \
    --gh-webhook-secret=<your-github-webhook-secret> \
    --repo-allowlist='github.com/your-org/*' \
    --repo-config=/home/atlantis/repo.yml \
    --enable-policy-checks
  ```
2. Send a pull request in GitHub to change something in Terraform, note the policy checks are performed.
3. Experiment with different cost policies by editing `policy.rego`.

## Running with GitLab

1. Run the `infracost/infracost-atlantis` image, which includes the Infracost CLI in addition to Atlantis:
  ```
  docker run -p 4141:4141 -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
    --mount type=bind,source=$(pwd)/examples/conftest/conftest.yml,target=/home/atlantis/repo.yml \
    --mount type=bind,source=$(pwd)/examples/conftest/policy,target=/home/atlantis/policy \
    infracost/infracost-atlantis:latest \
    --gitlab-user=<your-gitlab-user> \
    --gitlab-token=$GITLAB_TOKEN \
    --gitlab-webhook-secret=<your-gitlab-webhook-secret> \
    --repo-allowlist=<your-gitlab-repo-allowlist> \
    --repo-config=/home/atlantis/repo.yml \
    --enable-policy-checks
  ```
2. Send a merge request in GitLab to change something in Terraform, note the policy checks are performed.
3. Experiment with different cost policies by editing `policy.rego`.

## Running with Azure Repos

1. Run the `infracost/infracost-atlantis` image, which includes the Infracost CLI in addition to Atlantis:
  ```
  docker run -p 4141:4141 -e INFRACOST_API_KEY=$INFRACOST_API_KEY \
    --mount type=bind,source=$(pwd)/examples/conftest/conftest.yml,target=/home/atlantis/repo.yml \
    --mount type=bind,source=$(pwd)/examples/conftest/policy,target=/home/atlantis/policy \
    infracost/infracost-atlantis:latest \
    --azuredevops-user=<your-azure-devops-user> \
    --azuredevops-token=$AZURE_ACCESS_TOKEN \
    --azuredevops-webhook-user=<your-azure-devops-webhook-user> \
    --azuredevops-webhook-secret=<your-azure-devops-webhook-secret> \
    --repo-allowlist=<your-azure-repos-allowlist> \
    --repo-config=/home/atlantis/repo.yml \
    --enable-policy-checks
  ```
2. Send a merge request in GitLab to change something in Terraform, note the policy checks are performed.
3. Experiment with different cost policies by editing `policy.rego`.

## Usage

After a plan is created, Atlantis will run Infracost to generate cost estimates which evaluated against the policy with Conftest. If the plan does not pass the policy, Atlantis will not allow it to be applied until it's fixed to be in compliance, or approved by an authorized user:

![PolicyCheckError.png](PolicyCheckError.png)

When the policy check passes, the plan can be applied as usual:

![PolicyCheckPass.png](PolicyCheckPass.png)

See the [Atlantis documentation](https://www.runatlantis.io/docs/policy-checking.html#how-it-works) for more information.
