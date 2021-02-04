# Infracost Atlantis Integration

## Work in progress

Todo:

1. add github action to publish the docker image

2. provide example Atlantis config file:

```
docker run -p 4141:4141 -e INFRACOST_API_KEY=MY_API_KEY infracost-atlantis:latest server --gh-user=MY_GITHUB_USERNAME --gh-token=MY_GITHUB_TOKEN --gh-webhook-secret=MY_GITHUB_WEBHOOK_SECRET --repo-allowlist='github.com/infracost/infracost-atlantis' --repo-config-json='
{
  "repos": [
    {
      "id": "/.*/",
      "workflow": "terraform-infracost"
    }
  ],
  "workflows": {
    "terraform-infracost": {
      "plan": {
        "steps": [
          "init",
          "plan",
          {
            "run": "/infracost_atlantis_diff.sh"
          }
        ]
      }
    }
  }
}'
```

3. update readme with details of
  tfflags
  percentage_threshold
  pricing_api_endpoint
  usage_file
  atlantis_debug
  INFRACOST_API_KEY
  INFRACOST_LOG_LEVEL

