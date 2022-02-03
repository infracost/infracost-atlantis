# Contributing

🙌 Thank you for contributing and joining our mission to help engineers use cloud infrastructure economically and efficiently 🚀.

[Join our community Slack channel](https://www.infracost.io/community-chat) if you have any questions or need help contributing.

## Running Infracost Atlantis Docker image locally

Follow these steps to get the `infracost-atlantis` Docker image working locally with GitHub.

1. Clone the [infracost](https://github.com/infracost/infracost) repo
2. Clone this repo and `cd` into it
3. Make sure the `atlantis.env` file is filled out with the correct values.
   1. `ATLANTIS_GH_TOKEN` & `GITHUB_TOKEN` needs to be set to a personal GitHub access token with repo access
   2. `ATLANTIS_GH_WEBHOOK_SECRET` can be any long string - see step 8 for more into
   3. `ATLANTIS_REPO_ALLOWLIST` needs to be the repo you wish to test PR commenting on
   4. `INFRACOST_API_KEY` needs to be a valid Infracost api key
4. Place a `repos.yaml` file in the root of the project that contains the workflows you wish to test
5. Run `./docker-compose-dev.sh` setting `INFRACOST_REPO` variable to point to the relative path of the `infracost` repo
6. Create a test GitHub repository, populating it with a single `main.tf` file with [this content](https://github.com/infracost/gh-actions-demo/blob/master/terraform/main.tf).
7. Run `curl $(docker port infracost-atlantis_ngrok_1 4040)/api/tunnels | jq ."tunnels" | jq '.[0]' | jq ."public_url"` to get the public url of the ngrok tunnel to your local atlantis
8. Navigate to Settings > Webhooks > Add webhook
   1. Set the 'Payload URL' to the URL from the previous step + `/events` path
   2. For 'Content type' select 'application/json'
   3. For 'Which events would you like to trigger this webhook?' select 'Let me select individual events' and tick 'Pull requests', 'Issue comments' and 'Pushes'.
9. Make a change to the `main.tf` file and open a PR with it
10. If everything has run successfully you should see an output on your PR with Infracost results
