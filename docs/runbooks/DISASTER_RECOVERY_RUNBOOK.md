# Disaster recovery runbook

This runbook covers a site deployed with the included AWS templates. Adapt it
to the ownership, approval, and incident-management process of the new site.

## Recovery sources

- Git is the source of truth for configuration, layouts, and content.
- S3 versioning is enabled by the CloudFormation templates.
- CloudFormation is the source of truth for CDN, bucket, DNS, and monitoring.
- `.env` and AWS credentials are operator-owned configuration and are not
  stored in Git.

## Site-content rollback

Precondition: identify a reviewed commit or release tag that represents the
last known-good site.

1. Preserve current work and ensure the intended recovery commit exists on the
   remote.
2. Create a normal recovery branch from that commit.
3. Run:

   ```bash
   tools/scripts/article-validate.sh
   tools/scripts/dev.sh build
   ```

4. Review the generated site locally.
5. Use the normal staging deployment and acceptance process.
6. Deploy production only after staging is approved.

Expected result: CloudFront serves the recovered content after invalidation.
Confirm the homepage, representative pages, `robots.txt`, and canonical URLs.

`tools/scripts/restore.sh` is an optional interactive helper for repositories
that deliberately maintain `release-*` tags. It changes branches and performs
a hard reset. Read the script and preserve all local work before using it.

## Recover a deleted or overwritten object

Precondition: the production S3 bucket still exists and versioning was not
disabled.

1. Find the production bucket in the output of the production CloudFormation
   stack.
2. List object versions with the AWS console or AWS CLI.
3. Restore the required object version.
4. Invalidate the affected CloudFront path.
5. Confirm the public object and the page that references it.

Prefer a normal Git-based rebuild when the object is generated from repository
content.

## Rebuild infrastructure

Precondition: `.env` contains the intended domain, stack prefix, AWS account,
region, and ACM certificate ARN.

1. Confirm DNS and certificate ownership.
2. Deploy production infrastructure:

   ```bash
   aws/deploy-production-infra.sh
   ```

3. Confirm or restore Route 53 delegation at the registrar.
4. Deploy staging infrastructure:

   ```bash
   aws/deploy-staging-infra.sh
   ```

5. Deploy reviewed content to staging, then production.

Expected result: both stack deployments complete, DNS resolves to CloudFront,
and the distributions can read from their private S3 origins.

## Compromised credentials or exposed configuration

1. Stop using the exposed credential.
2. Rotate or revoke it in AWS or the affected provider.
3. Check CloudTrail and provider audit logs.
4. Remove the value from the working tree and Git history using an approved
   history-rewrite process.
5. Reissue deployments only after access is trusted.

An ACM certificate ARN or analytics ID is not usually an authentication
secret, but it still identifies infrastructure and should remain in local
configuration when practical.

## Recovery acceptance

- The intended commit is deployed.
- Production returns expected pages and assets.
- Canonical URLs use the production domain.
- Production permits indexing; staging blocks it.
- CloudFront and S3 error rates return to normal.
- No credential or private configuration was added to Git.
- The incident timeline, cause, and follow-up actions are recorded.

