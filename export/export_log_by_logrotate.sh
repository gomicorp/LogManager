# required args
# $1 : target path
# $2 : app name with env
 
# Variables For exporting App Logs
die() { status=$0; shift; echo "FATAL: $*"; exit $status; }
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
APP_NAME=$2
LOG_BUCKET="s3://log.gomi.cloudwatch"
TIME_STAMP=$(date "+%Y%m%d%H")

TARGET_PATH=$1
TARGET_FILE=${TARGET_PATH##*/}
TARGET_DIR=${TARGET_PATH%"$TARGET_FILE"}

exec "aws" "s3" "cp" "$TARGET_DIR" "${LOG_BUCKET}/${APP_NAME}/${EC2_INSTANCE_ID}/" "--recursive" "--exclude" "*" "--include" "${TARGET_FILE}-${TIME_STAMP}"

