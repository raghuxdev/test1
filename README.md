# InfraGuard Policy Check

A GitHub App that enforces infrastructure policies by analyzing Terraform configuration changes in pull requests.

## What It Does

InfraGuard checks **pull request diffs** (not entire files) to enforce policies on infrastructure changes. It currently focuses on preventing unauthorized AWS EC2 instance type upsizing.

### Key Features

- Detects instance type changes in Terraform files
- Blocks upsizing (e.g., t2.micro → t2.medium)
- Allows downsizing (e.g., t2.medium → t2.micro)
- Fails closed on variable references (can't evaluate dynamic values)
- Reports violations as GitHub Check Runs on pull requests

### How It Works

1. GitHub sends webhook when PR is opened/updated
2. InfraGuard analyzes the diff for instance type changes
3. Evaluates changes against policy rules
4. Creates a Check Run showing pass/fail status
5. Blocks merge if violations are detected

## Supported Resources

- `aws_instance` - EC2 instances
- `aws_launch_template` - Launch templates (for Auto Scaling Groups)
- `aws_autoscaling_group` - Auto scaling groups

## Instance Type Hierarchy

The app understands instance type sizes across families:

**T2/T3 Series** (Burstable):
- nano < micro < small < medium < large < xlarge < 2xlarge

**M5/M6i Series** (General Purpose):
- large < xlarge < 2xlarge < 4xlarge < ... < 24xlarge

**C5 Series** (Compute Optimized):
- large < xlarge < 2xlarge < ... < 24xlarge

**R5 Series** (Memory Optimized):
- large < xlarge < 2xlarge < ... < 24xlarge

## Quick Start

### Prerequisites

1. GitHub App created and installed on your repository
2. Java 17+ and Maven installed
3. Webhook secret configured

### Setup

1. Clone this repository
2. Configure webhook secret in `src/main/resources/application.properties`:
   ```properties
   github.webhook.secret=YOUR_WEBHOOK_SECRET
   ```
3. Run the application:
   ```bash
   ./mvnw quarkus:dev
   ```

### Testing

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive testing instructions.

Quick test workflow:
```bash
# 1. Commit base infrastructure
cp base-version.tf infrastructure/main.tf
git add infrastructure/main.tf
git commit -m "Add base infrastructure"
git push origin main

# 2. Create PR with upsize (should fail)
git checkout -b test/upsize
cp upsize-version-WILL-FAIL.tf infrastructure/main.tf
git add infrastructure/main.tf
git commit -m "Upsize instances"
git push origin test/upsize

# 3. Open PR and check for failure
```

## Test Files

This repository includes test Terraform files:

- `base-version.tf` - Baseline infrastructure (commit to main first)
- `upsize-version-WILL-FAIL.tf` - Contains upsizes (should fail check)
- `variable-version-WILL-FAIL.tf` - Uses variables (should fail check)

## Policy Rules

| Change Type | Example | Result |
|-------------|---------|--------|
| Upsize | t2.micro → t2.medium | FAIL |
| Downsize | t2.medium → t2.micro | PASS |
| Same size | t2.micro → t2.micro | PASS |
| Variable reference | "t2.micro" → var.size | FAIL |
| Cross-family upsize | t2.micro → m5.large | FAIL |

## Architecture

```
GitHub Webhook
    ↓
WebhookController (signature validation)
    ↓
TerraformParserService (parse diff, extract changes)
    ↓
PolicyEvaluationService (evaluate against rules)
    ↓
GitHubCheckRunService (create Check Run)
    ↓
GitHub PR (show pass/fail status)
```

## Configuration

Edit `src/main/resources/application.properties`:

```properties
# GitHub App Configuration
github.webhook.secret=${GITHUB_WEBHOOK_SECRET}
github.app.id=${GITHUB_APP_ID}
github.private.key.path=${GITHUB_PRIVATE_KEY_PATH}

# Server Configuration
quarkus.http.port=8080
```

## Troubleshooting

### Webhook signature validation fails
- Verify webhook secret matches GitHub App settings
- Restart application after updating secret

### No check run appears
- Confirm GitHub App is installed on repository
- Verify app has "Checks: Write" permission
- Check webhook delivery logs in GitHub App settings

### Check always passes when it should fail
- Ensure you're creating a PR (not just committing)
- Verify files have `.tf` extension
- Check application logs for parsing errors

## Development

### Build
```bash
./mvnw clean package
```

### Run tests
```bash
./mvnw test
```

### View logs
```bash
tail -f /tmp/quarkus-startup.log
```

## License

[Your License Here]

## Contributing

[Your Contributing Guidelines Here]
