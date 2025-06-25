#!/usr/bin/env bash
# Simple helper to create the default Firestore database for project `dinkdropzone`.
# Prerequisites:
#   1. Install the Google Cloud SDK -> https://cloud.google.com/sdk/docs/install
#   2. `gcloud auth login` and `gcloud config set project dinkdropzone`
#   3. (Optional) change LOCATION variable below if you need a different region.

set -euo pipefail

PROJECT_ID="dinkdropzone"
LOCATION="nam5"   # us-central (Iowa). Change if necessary.

function header() {
  echo "\n🔹 $1"
}

header "Enabling Firestore API for $PROJECT_ID …"
gcloud services enable firestore.googleapis.com --project "$PROJECT_ID"

header "Creating (default) Firestore database in $LOCATION …"
gcloud alpha firestore databases create \
  --project="$PROJECT_ID" \
  --database=default \
  --location="$LOCATION" \
  --type=firestore-native || {
  echo "Database already exists or creation failed."; exit 0; }

echo "\n✅  Firestore (default) created successfully." 