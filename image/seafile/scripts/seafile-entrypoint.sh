#!/bin/bash

DATADIR=${DATADIR:-"/seafile"}
BASEPATH=${BASEPATH:-"/opt/seafile"}
INSTALLPATH=${INSTALLPATH:-"${BASEPATH}/$(ls -1 ${BASEPATH} | grep -E '^seafile-server-[0-9.-]+')"}
VERSION=$(echo $INSTALLPATH | grep -oE [0-9.]+)
OLD_VERSION=$(cat $DATADIR/current_version 2> /dev/null || echo $VERSION)
MAJOR_VERSION=$(echo $VERSION | cut -d. -f 1-2)
OLD_MAJOR_VERSION=$(echo $OLD_VERSION | cut -d. -f 1-2)
VIRTUAL_PORT=${VIRTUAL_PORT:-"8000"}

python3 --version
uname -a
echo "Current seafile version: $VERSION ($MAJOR_VERSION)"
echo "Old seafile version: $OLD_VERSION ($OLD_MAJOR_VERSION)"


set -e
set -u
set -o pipefail

trapped() {
  control_seahub "stop"
  control_seafile "stop"
}

handle_error() {
  if [ "$1" != "0" ]; then
    # error handling goes here
    echo "Unclean shutdown: $1 , occurred on line $2"

    # Try to shutdown everything
    control_seahub "stop"
    control_seafile "stop"
  fi
}

autorun() {
  # Update if neccessary
  if [ $OLD_VERSION != $VERSION ]; then
    full_update
  fi
  echo $VERSION > $DATADIR/current_version
  # Needed to check the return code
  set +e
  control_seafile "start"
  local RET=$?
  set -e
  # Try an initial setup on error
  if [ ${RET} -eq 255 ]
  then
    choose_setup
    control_seafile "start"
  elif [ ${RET} -gt 0 ]
  then
    exit 1
  fi

  fix_gunicorn_config

  if [ ${SEAFILE_FASTCGI:-} ]
  then
    control_seahub "start-fastcgi"
  else
    control_seahub "start"
  fi
  keep_in_foreground
}

run_only() {
  local SH_DB_DIR="${DATADIR}/${SEAHUB_DB_DIR}"
  control_seafile "start"
  control_seahub "start"
  keep_in_foreground
}

choose_setup() {
  set +u
  # If $MYSQL_SERVER is set, we assume MYSQL setup is intended,
  # otherwise sqlite
  if [ -n "${MYSQL_SERVER}" ]
  then
    set -u
    setup_mysql
  else
    set -u
    setup_sqlite
  fi

}

setup_mysql() {
  echo "setup_mysql"

  # Wait for MySQL to boot up
  DOCKERIZE_TIMEOUT=${DOCKERIZE_TIMEOUT:-"60s"}
  dockerize -timeout ${DOCKERIZE_TIMEOUT} -wait tcp://${MYSQL_SERVER}:${MYSQL_PORT:-3306}

  set +u
  OPTIONAL_PARMS="$([ -n "${MYSQL_ROOT_PASSWORD}" ] && printf '%s' "-r ${MYSQL_ROOT_PASSWORD}")"
  set -u

  . /tmp/seafile.env; ${INSTALLPATH}/setup-seafile-mysql.sh auto \
    -n "${SEAFILE_NAME}" \
    -i "${SEAFILE_ADDRESS}" \
    -p "${SEAFILE_PORT}" \
    -d "${SEAFILE_DATA_DIR}" \
    -o "${MYSQL_SERVER}" \
    -t "${MYSQL_PORT:-3306}" \
    -u "${MYSQL_USER}" \
    -w "${MYSQL_USER_PASSWORD}" \
    -q "${MYSQL_USER_HOST:-"%"}" \
    ${OPTIONAL_PARMS}

  setup_seahub
  move_and_link
}

setup_sqlite() {
  echo "setup_sqlite"
  # Setup Seafile
  . /tmp/seafile.env; ${INSTALLPATH}/setup-seafile.sh auto \
    -n "${SEAFILE_NAME}" \
    -i "${SEAFILE_ADDRESS}" \
    -p "${SEAFILE_PORT}" \
    -d "${SEAFILE_DATA_DIR}"

  setup_seahub
  move_and_link
}

setup_seahub() {
  # Setup Seahub

  # From https://github.com/haiwen/seafile-server-installer-cn/blob/master/seafile-server-ubuntu-14-04-amd64-http
  sed -i 's/= ask_admin_email()/= '"\"${SEAFILE_ADMIN}\""'/' ${INSTALLPATH}/check_init_admin.py
  sed -i 's/= ask_admin_password()/= '"\"${SEAFILE_ADMIN_PW}\""'/' ${INSTALLPATH}/check_init_admin.py

  if [ "${SPRINTERNET_CUSTOMIZATIONS:-false}" = "true" ]; then
    echo Patching files...
    sed -i "/{% block main_content %}/a <script type=\"text/javascript\">window.location.replace(\"{% url 'oauth_login' %}\");</script>" ${INSTALLPATH}/seahub/seahub/templates/registration/login.html
    sed -i '/<\/div>/a <script type="text/javascript">window.location.replace("https://account.sprinternet.at/ssologout?src=seafile");</script>' ${INSTALLPATH}/seahub/seahub/templates/registration/logout.html
    echo Patching completed...
  fi

  control_seafile "start"

  . /tmp/seafile.env; python3 -t ${INSTALLPATH}/check_init_admin.py
}

move_and_link() {
  # As seahub.db is normally in the root dir of seafile (/opt/seafile)
  # SEAHUB_DB_DIR needs to be defined if it should be moved elsewhere under /seafile
  local SH_DB_DIR="${DATADIR}/${SEAHUB_DB_DIR}"
  # Stop Seafile/hub instances if running
  control_seahub "stop"
  control_seafile "stop"

  move_files "${SH_DB_DIR}"
  link_files "${SH_DB_DIR}"

  if [ ! -w ${DATADIR} ]; then
    echo "Updating file permissions"
    chown -R root:root ${DATADIR}/
  fi
}

fix_gunicorn_config() {
  echo "Fixing gunicorn config."
  # Must bind 0.0.0.0 instead of 127.0.0.1
  CONFIG_FILE=/seafile/conf/gunicorn.conf.py
  OLD="bind = \"127.0.0.1:${VIRTUAL_PORT}\""
  NEW="bind = \"0.0.0.0:${VIRTUAL_PORT}\""
  sed -i "s/${OLD}/${NEW}/g" $CONFIG_FILE
}

move_files() {
  MOVE_LIST=(
    "${BASEPATH}/ccnet:${DATADIR}/ccnet"
    "${BASEPATH}/conf:${DATADIR}/conf"
    "${BASEPATH}/seafile-data:${DATADIR}/seafile-data"
    "${BASEPATH}/seahub-data:${DATADIR}/seahub-data"
    "${INSTALLPATH}/seahub/media/avatars:${DATADIR}/seahub-data/avatars"
    "${INSTALLPATH}/seahub/media/custom:${DATADIR}/seahub-data/custom"
  )
  for SEADIR in ${MOVE_LIST[@]}
  do
    ARGS=($(echo $SEADIR | tr ":" "\n"))
    if [ -e "${ARGS[0]}" ] && [ ! -e "${ARGS[1]}" ]
    then
      echo "Copying ${ARGS[0]} => ${ARGS[1]}"
      local PARENT=$(dirname ${ARGS[1]})
      if [ ! -e $PARENT ]
      then
        mkdir -p $PARENT
      fi
      cp -a ${ARGS[0]}/ ${ARGS[1]}
    fi
    if [ -e "${ARGS[0]}" ] && [ ! -L "${ARGS[0]}" ]
    then
      echo "Dropping ${ARGS[0]}"
      rm -rf ${ARGS[0]}
    fi
  done

  if [ -e "${BASEPATH}/seahub.db" -a ! -L "${BASEPATH}/seahub.db" ]
  then
    mv ${BASEPATH}/seahub.db ${1}/
  fi
}

link_files() {
  LINK_LIST=(
    "${DATADIR}/ccnet:${BASEPATH}/ccnet"
    "${DATADIR}/conf:${BASEPATH}/conf"
    "${DATADIR}/seafile-data:${BASEPATH}/seafile-data"
    "${DATADIR}/seahub-data:${BASEPATH}/seahub-data"
    "${DATADIR}/seahub-data/avatars:${INSTALLPATH}/seahub/media/avatars"
    "${DATADIR}/seahub-data/custom:${INSTALLPATH}/seahub/media/custom"

  )
  for SEADIR in ${LINK_LIST[@]}
  do
    ARGS=($(echo $SEADIR | tr ":" "\n"))
    if [ -e "${ARGS[0]}" ]
    then
      echo "Linking ${ARGS[1]} => ${ARGS[0]}"
      ln -sf ${ARGS[0]} ${ARGS[1]}
    fi
  done
  if [ -e "${SH_DB_DIR}/seahub.db" -a ! -L "${BASEPATH}/seahub.db" ]
  then
    ln -s ${1}/seahub.db ${BASEPATH}/seahub.db
  fi

}

keep_in_foreground() {
  echo "Running main progress in foreground now..."
  # As there seems to be no way to let Seafile processes run in the foreground we
  # need a foreground process. This has a dual use as a supervisor script because
  # as soon as one process is not running, the command returns an exit code >0
  # leading to a script abortion thanks to "set -e".
  while true
  do
    for SEAFILE_PROC in "seafile-control" "seaf-server" "gunicorn"
    do
      pkill -0 -f "${SEAFILE_PROC}"
      sleep 1
    done
    sleep 5
  done
}

prepare_env() {
  cat << _EOF_ > /tmp/seafile.env
  export LANG='en_US.UTF-8'
  export LC_ALL='en_US.UTF-8'
  export CCNET_CONF_DIR="${BASEPATH}/ccnet"
  export SEAFILE_CONF_DIR="${SEAFILE_DATA_DIR}"
  export SEAFILE_CENTRAL_CONF_DIR="${BASEPATH}/conf"
  export PYTHONPATH=${INSTALLPATH}/seafile/lib/python3.6/site-packages:${INSTALLPATH}/seafile/lib64/python3.6/site-packages:${INSTALLPATH}/seahub:${INSTALLPATH}/seahub/thirdpart:${INSTALLPATH}/seafile/lib/python3.6/site-packages:${INSTALLPATH}/seafile/lib64/python3.6/site-packages:${PYTHONPATH:-}

_EOF_
}

control_seafile() {
  . /tmp/seafile.env; ${INSTALLPATH}/seafile.sh "$@"
  local RET=$?
  if [ $RET -gt 0 ]; then
    print_log
  fi
  return ${RET}
}

control_seahub() {
  . /tmp/seafile.env; ${INSTALLPATH}/seahub.sh "$@"
  local RET=$?
  if [ $RET -gt 0 ]; then
    print_log
  fi
  return ${RET}
}

print_log() {
    if [ -e $INSTALLPATH/../logs ]
    then
      sleep 2
      echo ""
      echo "---------------------------------------"
      echo "seafile.log:"
      echo "---------------------------------------"
      cat $INSTALLPATH/../logs/seafile.log
      echo ""
      echo "---------------------------------------"
      echo "controller.log:"
      echo "---------------------------------------"
      cat $INSTALLPATH/../logs/controller.log
      echo ""
      echo "---------------------------------------"
      echo "ccnet.log:"
      echo "---------------------------------------"
      cat $INSTALLPATH/../logs/ccnet.log
    fi
}

full_update(){
  EXECUTE=""
  echo ""
  echo "---------------------------------------"
  echo "Upgrading from $OLD_VERSION to $VERSION"
  echo "---------------------------------------"
  echo ""
  # Iterate through all the major upgrade scripts and apply them
  for i in `ls ${INSTALLPATH}/upgrade/`; do
    if [ `echo $i | grep "upgrade_${OLD_MAJOR_VERSION}"` ]; then
      EXECUTE=1
    fi
    if [ $EXECUTE ] && [ `echo $i | grep upgrade` ]; then
      echo "Running update $i"
      update $i || exit
    fi
  done
  # When all the major upgrades are done, perform a minor upgrade
  if [ -z $EXECUTE ]; then
    echo "Running minor upgrade"
    update minor-upgrade.sh
    echo $VERSION > $DATADIR/current_version
  fi
}

update(){
  . /tmp/seafile.env; echo -ne '\n' | ${INSTALLPATH}/upgrade/$@
  local RET=$?
  sleep 1
  return ${RET}
}

collect_garbage(){
  . /tmp/seafile.env; ${INSTALLPATH}/seaf-gc.sh $@
  local RET=$?
  sleep 1
  return ${RET}
}

diagnose(){
  . /tmp/seafile.env; ${INSTALLPATH}/seaf-fsck.sh $@
  local RET=$?
  sleep 1
  return ${RET}
}

maintenance(){
  local SH_DB_DIR="${DATADIR}/${SEAHUB_DB_DIR}"
  # Linking must always be done
  link_files "${SH_DB_DIR}"
  echo ""
  echo "---------------------------------------"
  echo "Running in maintenance mode"
  echo "---------------------------------------"
  echo ""
  tail -f /dev/null
}


# Fill vars with defaults if empty
if [ -z ${MODE+x} ]; then
  MODE=${1:-"run"}
fi

SEAFILE_DATA_DIR=${SEAFILE_DATA_DIR:-"${DATADIR}/seafile-data"}
SEAFILE_PORT=${SEAFILE_PORT:-8082}
SEAHUB_DB_DIR=${SEAHUB_DB_DIR:-}

prepare_env

trap trapped SIGINT SIGTERM
trap 'handle_error $? $LINENO' EXIT

move_and_link
case $MODE in
  "autorun" | "run")
    autorun
  ;;
  "setup" | "setup_mysql")
    setup_mysql
  ;;
  "setup_sqlite")
    setup_sqlite
  ;;
  "setup_seahub")
    setup_seahub
  ;;
  "setup_only")
    choose_setup
  ;;
  "run_only")
    run_only
  ;;
  "update")
    full_update
  ;;
  "diagnose")
    diagnose
  ;;
  "collect_garbage")
    collect_garbage
  ;;
  "maintenance")
    maintenance
  ;;
  "stop")
    trapped
  ;;
esac