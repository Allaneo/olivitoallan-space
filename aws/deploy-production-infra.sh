#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tools/scripts/load-env.sh"

DOMAIN="${DOMAIN_NAME:-}"
STACK_NAME="${STACK_NAME_PREFIX:-website}-production"
MODE="${ROBOTS_POLICY_MODE:-Indexable}"
CERT_ARN="${ACM_CERTIFICATE_ARN:-}"
GOOGLE_CODE="${GOOGLE_VERIFICATION_CODE:-}"

if [[ -z "$DOMAIN" || "$DOMAIN" == "example.org" ]]; then
  echo "Set DOMAIN_NAME in .env before deploying infrastructure." >&2
  exit 1
fi

if [[ -z "$CERT_ARN" || "$CERT_ARN" == *"000000000000"* ]]; then
  echo "Set ACM_CERTIFICATE_ARN in .env to a certificate in us-east-1." >&2
  exit 1
fi

echo "Deploying production infrastructure: $STACK_NAME"
aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/cdn-site.yaml" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    DomainName="$DOMAIN" \
    AcmCertificateArn="$CERT_ARN" \
    RobotsPolicyMode="$MODE" \
    GoogleVerificationCode="$GOOGLE_CODE" \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

echo "Production infrastructure is ready at https://$DOMAIN"

