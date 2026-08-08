#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tools/scripts/load-env.sh"

DOMAIN="${DOMAIN_NAME:-}"
STACK_NAME="${STACK_NAME_PREFIX:-website}-staging"
CERT_ARN="${ACM_CERTIFICATE_ARN:-}"

if [[ -z "$DOMAIN" || "$DOMAIN" == "example.org" ]]; then
  echo "Set DOMAIN_NAME in .env before deploying infrastructure." >&2
  exit 1
fi

if [[ -z "$CERT_ARN" || "$CERT_ARN" == *"000000000000"* ]]; then
  echo "Set ACM_CERTIFICATE_ARN in .env to a certificate in us-east-1." >&2
  exit 1
fi

HOSTED_ZONE_ID="$(
  aws route53 list-hosted-zones-by-name \
    --dns-name "$DOMAIN" \
    --query 'HostedZones[0].Id' \
    --output text
)"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID#/hostedzone/}"

if [[ -z "$HOSTED_ZONE_ID" || "$HOSTED_ZONE_ID" == "None" ]]; then
  echo "No Route 53 hosted zone was found for $DOMAIN." >&2
  echo "Deploy production infrastructure first." >&2
  exit 1
fi

echo "Deploying staging infrastructure: $STACK_NAME"
aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/staging-cdn-site.yaml" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    StagingDomainName="staging.$DOMAIN" \
    AcmCertificateArn="$CERT_ARN" \
    RootHostedZoneId="$HOSTED_ZONE_ID" \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

echo "Staging infrastructure is ready at https://staging.$DOMAIN"

