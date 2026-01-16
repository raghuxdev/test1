# Test Terraform Files for InfraGuard

This directory contains test Terraform files to validate the InfraGuard policy checking functionality.

## Files

### 1. `base-version.tf`
**Purpose**: Baseline file to commit to your main branch first
**Instance Types**:
- `aws_instance.web`: `t2.micro`
- `aws_launch_template.api`: `t2.small`
- `aws_launch_template.workers_lt`: `t3.micro`

**Action**: Commit this to `main` branch as your starting point

---

### 2. `upsize-version-WILL-FAIL.tf` ❌
**Purpose**: Test upsize detection (policy violation)
**Changes from base**:
- `aws_instance.web`: `t2.micro` → `t2.medium` ❌ (upsize)
- `aws_launch_template.api`: `t2.small` → `t2.large` ❌ (upsize)
- `aws_launch_template.workers_lt`: `t3.micro` → `t3.small` ❌ (upsize)

**Expected Result**: Check run FAILS with 3 violations

---

### 3. `downsize-version-WILL-PASS.tf` ✅
**Purpose**: Test downsize allowance (policy compliant)
**Changes from base**:
- `aws_instance.web`: `t2.micro` → `t2.nano` ✅ (downsize)
- `aws_launch_template.api`: `t2.small` → `t2.micro` ✅ (downsize)
- `aws_launch_template.workers_lt`: `t3.micro` → `t3.micro` ✅ (no change)

**Expected Result**: Check run PASSES

---

### 4. `variable-version-WILL-FAIL.tf` ❌
**Purpose**: Test variable reference detection (fail-closed)
**Changes from base**:
- `aws_instance.web`: `t2.micro` → `var.instance_type` ❌ (variable)
- `aws_launch_template.api`: `t2.small` → `var.api_instance_type` ❌ (variable)
- `aws_launch_template.workers_lt`: `t3.micro` → `local.worker_instance_type` ❌ (local)

**Expected Result**: Check run FAILS with message about variable references

---

### 5. `sample-diff-upsize.txt`
**Purpose**: Example of what the GitHub webhook diff looks like
This is what the TerraformParserService actually parses.

---

### 6. `TESTING_GUIDE.md`
**Purpose**: Complete step-by-step testing instructions
Read this for full testing workflow.

---

## Quick Start

### Before Testing - Fix Webhook Secret!

**You MUST fix the webhook secret first**, or webhooks will be rejected:

```bash
# 1. Get secret from GitHub App settings
open https://github.com/settings/apps/infra-guardian-triggerbird

# 2. Update application.properties (line 29)
# github.webhook.secret=${GITHUB_WEBHOOK_SECRET:YOUR_ACTUAL_SECRET}

# 3. Restart app
./mvnw quarkus:dev
```

Look for this in logs:
```
✅ Webhook signature validation PASSED
```

---

## Testing Workflow

```bash
# 1. Commit base version to main
git checkout main
cp test-terraform/base-version.tf infrastructure/main.tf
git add infrastructure/main.tf
git commit -m "Add base infrastructure"
git push origin main

# 2. Create test branch with upsize
git checkout -b test/upsize-fail
cp test-terraform/upsize-version-WILL-FAIL.tf infrastructure/main.tf
git add infrastructure/main.tf
git commit -m "Increase instance sizes"
git push origin test/upsize-fail

# 3. Create PR on GitHub
# Expected: Check run FAILS ❌

# 4. Create test branch with downsize
git checkout main
git checkout -b test/downsize-pass
cp test-terraform/downsize-version-WILL-PASS.tf infrastructure/main.tf
git add infrastructure/main.tf
git commit -m "Reduce instance sizes"
git push origin test/downsize-pass

# 5. Create PR on GitHub
# Expected: Check run PASSES ✅
```

---

## What Gets Checked

The policy checks these Terraform resources:
- ✅ `aws_instance` - EC2 instances
- ✅ `aws_launch_template` - Launch templates (for ASG)
- ✅ `aws_autoscaling_group` - Auto scaling groups

For these changes:
- ❌ **BLOCKED**: Any instance type upsize
- ✅ **ALLOWED**: Downsizing or same size
- ❌ **BLOCKED**: Variable references (fail-closed for security)

---

## Instance Type Hierarchy

Supported instance types (by size tier):

**T2/T3 Series** (Burstable):
- `t2.nano` / `t3.nano` (10)
- `t2.micro` / `t3.micro` (20)
- `t2.small` / `t3.small` (30)
- `t2.medium` / `t3.medium` (40)
- `t2.large` / `t3.large` (50)
- `t2.xlarge` / `t3.xlarge` (60)
- `t2.2xlarge` / `t3.2xlarge` (70)

**M5/M6i Series** (General Purpose):
- `m5.large` / `m6i.large` (100)
- `m5.xlarge` / `m6i.xlarge` (110)
- `m5.2xlarge` / `m6i.2xlarge` (120)
- ... up to 24xlarge (170)

**C5 Series** (Compute Optimized):
- `c5.large` (200)
- ... up to `c5.24xlarge` (270)

**R5 Series** (Memory Optimized):
- `r5.large` (300)
- ... up to `r5.24xlarge` (370)

---

## Troubleshooting

### Problem: Check run always passes

**Check**:
1. Is the webhook secret correct? (logs show signature validation passed)
2. Are you changing the `.tf` file in a PR? (not just committing to main)
3. Does the diff show `- instance_type = "old"` and `+ instance_type = "new"`?
4. Check logs: `tail -f /tmp/quarkus-startup.log`

### Problem: No check run appears

**Check**:
1. Is the GitHub App installed on the repo?
2. Is the app subscribed to `pull_request` events?
3. Is the webhook URL correct?
4. Check GitHub App webhook delivery logs

### Problem: Signature validation fails

**Fix**:
1. Get the EXACT secret from GitHub App settings
2. Update `application.properties` line 29
3. Restart the app
4. Test again

---

## Files Summary

| File | Purpose | Expected Result |
|------|---------|-----------------|
| `base-version.tf` | Starting point | Commit to main |
| `upsize-version-WILL-FAIL.tf` | Test blocking | ❌ Check FAILS |
| `downsize-version-WILL-PASS.tf` | Test allowing | ✅ Check PASSES |
| `variable-version-WILL-FAIL.tf` | Test fail-closed | ❌ Check FAILS |

---

## Next Steps

1. ✅ Fix webhook secret
2. ✅ Create test repository
3. ✅ Install GitHub App on test repo
4. ✅ Follow testing workflow above
5. ✅ Verify check runs appear correctly
6. ✅ Deploy to production

For detailed instructions, see `TESTING_GUIDE.md`.
