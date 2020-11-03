#!/bin/bash

# 이 스크립트는 log rotate가 실행된 이후 실행됩니다.
# $1 : lotate될 파일의 path pattern입니다. ex /opt/nginx/logs/*.log
# $2 : 저장될 경로를 구성하는, 해당 앱의 식별자입니다.
# $2의 정체가 불분명합니다. lotate 상황에 따라서 $1에 담겨야 하는 pattern이 분리되어서 별도의 arg로 들어오
는 것 같습니다. 이에 맞춰서 로직을 수정하고 테스트 하는 파일입니다.

# lotate된 시점의 time stamp입니다. 업로드 할 파일을 선택하는 패턴으로 사용됩니다.
TIME_STAMP=$(date "+%Y%m%d%H")

# 단순한 로깅 함수입니다.
logging()
{
  NOW=$(date "+%Y-%m-%d %H:%M:%S")
  arg_count="$#"
  args=($*)

  echo "======== TIME : ${NOW} ========"
  echo "arg count : ${arg_count}"

  for (( i=0; i<${#args[@]}; i++ )) ; do
    (( arg_index=$i + 1 ))
    echo "arg ${arg_index} : ${args[i]}"
  done
}

# 해당 파일에 arg를 로깅합니다.
logging $* >> /home/ec2-user/LogManager/export/logrotate_args.log

# 해당 ec2의 instance id 입니다.
die() { status=$0; shift; echo "FATAL: $*"; exit $status; }
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"

# log 파일을 저장할 s3 bucket url 입니다.
LOG_BUCKET="s3://log.gomi.cloudwatch"

# $1 인자가 와일드카드가 포함된 pattern형태로 들어오면 총 인자 수는 3개 미만입니다.
# 이 경우 마지막 인자가 되는 $2는 앱의 식별자인 APP_NAME입니다.
# PATHS에 pattern을 넣습니다. for loop 처리를 위해 list형태로 저장합니다.
if [ $# -lt 3 ] ; then

  APP_NAME=$2
  PATHS=("$1")

fi

# $1 인자가 pattern형태의 단일인자가 아닌 경우, 총 인자의 수는 3개 이상이 됩니다.
# 현재 저장 경로 버그를 일으키고 있는 케이스로, 마지막 인자가 APP_NAME이 되고 이전 인자들은 전부 타겟 파일의 path인 것으로 예상 됩니다.
# 마지막 인자를 APP_NAME으로, 나머지를 PATHS 리스트로 저장합니다.
if [ $# -ge 3 ] ; then

  APP_NAME=${*: -1}
  length=$(($#-1))
  PATHS=${@:1:$length}

fi

# PATHS에 들어있는 파일을 업로드 합니다.
for TARGET_PATH in ${PATHS[@]} ; do

  # path 형식의 마지막에 있는 파일명 혹은 파일명패턴을 분리합니다.
  TARGET_FILE=${TARGET_PATH##*/}
  # 파일명 혹은 파일명패턴을 제외한 dir을 분리합니다.
  TARGET_DIR=${TARGET_PATH%"$TARGET_FILE"}
  # aws s3 cli를 사용하여 업로드 합니다.
  # recursive 옵션으로 여러 파일을 선택하게 하고, exclude와 include 옵션으로 파일명 또는 파일명패턴에 따라 파일을 선택합니다.
  aws s3 cp "$TARGET_DIR" "${LOG_BUCKET}/${APP_NAME}/${EC2_INSTANCE_ID}/" --recursive --exclude "*" --include "${TARGET_FILE}-${TIME_STAMP}*"

done

