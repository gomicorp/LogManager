# Variables For exporting App Logs
MY_APP_ROOT=/home/ec2-user/YAC
RAILS_ENV=staging
die() { status=$1; shift; echo "FATAL: $*"; exit $status; }
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
APP_NAME="YAC-staging"
LOG_BUCKET="s3://log.gomi.cloudwatch"
YES_DAY_STAMP=$(date -d "1 day ago" "+%Y%m%d")

TARGET_PATH=$1
TARGET_FILE=${TARGET_PATH##*/}
TARGET_DIR=${TARGET_PATH%$TARGET_FILE}

exec "aws" "s3" "cp" "$TARGET_DIR" "$LOG_BUCKET/$APP_NAME/$EC2_INSTANCE_ID/" "--recursive" "--exclude" "*" "--include" "*$TARGET_FILE-$YES_DAY_STAMP*"

