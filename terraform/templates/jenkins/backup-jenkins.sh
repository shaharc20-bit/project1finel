#!/usr/bin/env bash
set -euo pipefail
export PATH="$PATH:/snap/bin:/usr/local/bin"

: "${BUCKET:?BUCKET is not set}"
archive="/tmp/jenkins-home-$(date +%F-%H%M).tgz"

tar -czf "$archive" -C /var/jenkins_home \
  --exclude=./workspace --exclude=./caches --exclude=./war --exclude=./.cache .

aws s3 cp "$archive" "s3://$BUCKET/jenkins/$(basename "$archive")" --region "${AWS_REGION:-eu-north-1}"
rm -f "$archive"
echo "Backup uploaded to s3://$BUCKET/jenkins/"
