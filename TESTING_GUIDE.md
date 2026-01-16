# Testing Guide for InfraGuard Policy Check

## Important: How the GitHub App Works

The InfraGuard app **does NOT check entire files**. It checks the **DIFF** (changes) in a pull request.

This means:
- ✅ It detects when you change `instance_type = "t2.micro"` to `instance_type = "t2.medium"`
- ❌ It does NOT scan your entire repo for instance types

---

## Testing Workflow

### Step 1: Fix the Webhook Secret First

Before testing, you MUST fix the webhook signature validation:

1. Go to: https://github.com/settings/apps/infra-guardian-triggerbird
2. Click "Webhook" in the sidebar
3. Get/regenerate the webhook secret
4. Update `src/main/resources/application.properties` line 29
5. Restart the app: `./mvnw quarkus:dev`

**You'll know it's working when you see:**
```
✅ Webhook signature validation PASSED
```

---

### Step 2: Create a Test Repository

1. Create a new test repo (or use an existing one)
2. Install your GitHub App on that repo
3. Make sure the app has access to the repo

---

### Step 3: Test Scenario 1 - Upsize Detection (SHOULD FAIL)

**Goal**: Detect and block instance type upsizing

**Steps**:
1. **On main branch**: Commit `base-version.tf`
   ```bash
   cp base-version.tf infrastructure/main.tf
   git add infrastructure/main.tf
   git commit -m "Add base infrastructure"
   git push origin main
   ```

2. **Create feature branch**:
   ```bash
   git checkout -b test/upsize-instances
   ```

3. **Make changes**: Copy the upsize version
   ```bash
   cp upsize-version-WILL-FAIL.tf infrastructure/main.tf
   ```

4. **Commit and push**:
   ```bash
   git add infrastructure/main.tf
   git commit -m "Increase instance sizes"
   git push origin test/upsize-instances
   ```

5. **Create PR**: Create a pull request from `test/upsize-instances` to `main`

6. **Expected Result**:
   - GitHub Check Run appears: "Infra Guard"
   - Status: ❌ **FAILED**
   - Message shows:
     ```
     **3 policy violation(s) detected.**

     - aws_instance.web in infrastructure/main.tf: Instance type upsize detected: t2.micro → t2.medium
     - aws_launch_template.api in infrastructure/main.tf: Instance type upsize detected: t2.small → t2.large
     - aws_launch_template.workers_lt in infrastructure/main.tf: Instance type upsize detected: t3.micro → t3.small
     ```

---

### Step 4: Test Scenario 2 - Downsize (SHOULD PASS)

**Note**: The `downsize-version-WILL-PASS.tf` file is currently missing from the repository. You'll need to create this file or manually edit `infrastructure/main.tf` to downsize instance types for this test.

**Goal**: Allow instance type downsizing

**Steps**:
1. **Create feature branch**:
   ```bash
   git checkout main
   git checkout -b test/downsize-instances
   ```

2. **Make changes**:
   ```bash
   cp downsize-version-WILL-PASS.tf infrastructure/main.tf
   ```

3. **Commit and push**:
   ```bash
   git add infrastructure/main.tf
   git commit -m "Reduce instance sizes for cost savings"
   git push origin test/downsize-instances
   ```

4. **Create PR**: Create a pull request from `test/downsize-instances` to `main`

5. **Expected Result**:
   - GitHub Check Run appears: "Infra Guard"
   - Status: ✅ **PASSED**
   - Message shows:
     ```
     All instance type changes are within policy limits.

     **Detected Changes:**
     - aws_instance.web in infrastructure/main.tf: t2.micro → t2.nano ✓
     - aws_launch_template.api in infrastructure/main.tf: t2.small → t2.micro ✓
     ```

---

### Step 5: Test Scenario 3 - Variable References (SHOULD FAIL)

**Goal**: Fail closed when variables are used (can't evaluate)

**Steps**:
1. **Create feature branch**:
   ```bash
   git checkout main
   git checkout -b test/use-variables
   ```

2. **Make changes**:
   ```bash
   cp variable-version-WILL-FAIL.tf infrastructure/main.tf
   ```

3. **Commit and push**:
   ```bash
   git add infrastructure/main.tf
   git commit -m "Refactor to use variables"
   git push origin test/use-variables
   ```

4. **Create PR**: Create a pull request from `test/use-variables` to `main`

5. **Expected Result**:
   - GitHub Check Run appears: "Infra Guard"
   - Status: ❌ **FAILED**
   - Message shows:
     ```
     **Policy violation(s) detected.**

     - aws_instance.web in infrastructure/main.tf: Instance type uses variable reference: t2.micro → var.instance_type.
       Policy requires hardcoded instance types for evaluation.
       Please either: (1) use hardcoded instance type values, or (2) get approval from infrastructure team to bypass this check.
     ```

---

## Debugging

### Check Application Logs

Watch the logs in real-time:
```bash
tail -f /tmp/quarkus-startup.log
```

**Look for these key log lines:**

1. **Webhook received**:
   ```
   Received GitHub webhook: event=pull_request, delivery=xxx
   ```

2. **Signature validation**:
   ```
   ✅ Webhook signature validation PASSED
   ```
   or
   ```
   ❌ Webhook signature validation FAILED
   ```

3. **File parsing**:
   ```
   Analyzing Terraform file: infrastructure/main.tf
   Found resource declaration: aws_instance.web at line 5
   Removed instance_type: t2.micro (resource: web)
   Added instance_type: t2.medium (resource: web)
   Detected instance type change in infrastructure/main.tf: t2.micro -> t2.medium (resource: web)
   ```

4. **Policy evaluation**:
   ```
   Policy violation: aws_instance.web in infrastructure/main.tf: Instance type upsize detected: t2.micro → t2.medium
   ```

5. **Check run creation**:
   ```
   Creating GitHub check run for PR #1
   Check run created: https://github.com/owner/repo/runs/12345
   ```

---

## What the Diff Looks Like

When you create a PR, GitHub sends a diff like this:

```diff
diff --git a/infrastructure/main.tf b/infrastructure/main.tf
index abc123..def456 100644
--- a/infrastructure/main.tf
+++ b/infrastructure/main.tf
@@ -1,7 +1,7 @@
 resource "aws_instance" "web" {
   ami           = "ami-0c55b159cbfafe1f0"
-  instance_type = "t2.micro"
+  instance_type = "t2.medium"

   tags = {
     Name = "web-server"
```

The parser looks for:
- Lines starting with `-` (removed): `- instance_type = "t2.micro"`
- Lines starting with `+` (added): `+ instance_type = "t2.medium"`

---

## Common Issues

### Issue 1: Webhook Not Received

**Symptoms**: No logs showing webhook received

**Solutions**:
- Check GitHub App webhook settings
- Verify webhook URL is correct (e.g., `https://your-domain.com/api/webhooks/github`)
- Check if app is installed on the repo
- Check if app is subscribed to `pull_request` events

### Issue 2: Signature Validation Fails

**Symptoms**: Logs show `❌ Webhook signature validation FAILED`

**Solutions**:
- Get correct webhook secret from GitHub App settings
- Update `application.properties`
- Restart the application

### Issue 3: No Instance Types Detected

**Symptoms**: Check run passes but should fail

**Solutions**:
- Make sure you're actually changing `instance_type` in the diff
- Check logs for "Analyzing Terraform file" messages
- Verify the file has `.tf` extension
- Make sure the diff shows `- instance_type = "old"` and `+ instance_type = "new"`

### Issue 4: Check Run Not Created

**Symptoms**: Webhook received but no check run on GitHub

**Solutions**:
- Check if GitHub App private key is valid
- Check if installation ID is correct
- Check logs for "Creating GitHub check run" message
- Verify app has "Checks: Write" permission

---

## Quick Test Command

For a quick test without going through GitHub, you can test the parser directly:

```bash
# Create a sample diff
cat > /tmp/test.diff << 'EOF'
diff --git a/main.tf b/main.tf
--- a/main.tf
+++ b/main.tf
@@ -1,5 +1,5 @@
 resource "aws_instance" "web" {
-  instance_type = "t2.micro"
+  instance_type = "t2.medium"
 }
EOF

# Test with curl (after fixing webhook secret)
curl -X POST http://localhost:8080/api/webhooks/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-GitHub-Delivery: test-123" \
  -H "X-Hub-Signature-256: sha256=YOUR_SIGNATURE_HERE" \
  -d @test-pr-payload.json
```

---

## Success Criteria

You'll know everything is working when:

1. ✅ Webhook signature validation passes
2. ✅ TerraformParserService detects instance type changes
3. ✅ PolicyEvaluationService correctly identifies upsizes vs downsizes
4. ✅ GitHub Check Run appears on the PR
5. ✅ Check Run shows correct status (pass/fail)
6. ✅ Check Run shows detailed violation messages

---

## Next Steps

Once basic testing works:

1. Test with real infrastructure repositories
2. Add more instance type families to the hierarchy (if needed)
3. Configure monitoring/alerting for webhook failures
4. Set up production deployment
5. Document the policy for your team
