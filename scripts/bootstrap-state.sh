#!/usr/bin/env bash
# ============================================================
# bootstrap-state.sh
# Creates the S3 bucket and DynamoDB table for Terraform state
# Run ONCE before any `terraform init`.
# Usage: ./scripts/bootstrap-state.sh <aws-region> <project>
# Example: ./scripts/bootstrap-state.sh ap-south-1 app
# ============================================================
set -euo pipefail

REGION="${1:-ap-south-1}"
PROJECT="${2:-app}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${PROJECT}-tfstate-${ACCOUNT_ID}"
TABLE="${PROJECT}-tfstate-lock"

echo "==> Bootstrapping Terraform backend"
echo "    Region  : $REGION"
echo "    Bucket  : $BUCKET"
echo "    DynTable: $TABLE"
echo ""

# ── S3 Bucket ────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "[skip] Bucket $BUCKET already exists"
else
  echo "[create] S3 bucket: $BUCKET"
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]
    }'

  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "[ok] S3 bucket ready"
fi

# ── DynamoDB Table ────────────────────────────────────────────
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" 2>/dev/null; then
  echo "[skip] DynamoDB table $TABLE already exists"
else
  echo "[create] DynamoDB table: $TABLE"
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
  echo "[ok] DynamoDB table ready"
fi

echo ""
echo "==> Backend bootstrap complete."
echo ""
echo "Add the following to each environment's backend.tf:"
echo "──────────────────────────────────────────────────"
echo 'terraform {'
echo '  backend "s3" {'
echo "    bucket         = \"$BUCKET\""
echo "    region         = \"$REGION\""
echo '    key            = "<env>/terraform.tfstate"'
echo "    dynamodb_table = \"$TABLE\""
echo '    encrypt        = true'
echo '  }'
echo '}'
