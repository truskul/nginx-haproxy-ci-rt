#!/usr/bin/env bash

export PS4='+ $0:$LINENO '

HAPROXY_VALID_MSG=${HAPROXY_VALID_MSG:-"Looks good - reload completed."}
HAPROXY_INVALID_MSG=${HAPROXY_INVALID_MSG:-"Invalid HAProxy configuration - check the logs, leaving old config.."}

ENABLE_SYN_DROP="sudo iptables -I INPUT -p tcp -m multiport --dport ${HAPROXY_PORTS} --syn -j DROP"
DISABLE_SYN_DROP="sudo iptables -D INPUT -p tcp -m multiport --dport ${HAPROXY_PORTS} --syn -j DROP"

HAPROXY_CONFIG=${HAPROXY_CONFIG:-"/etc/haproxy/haproxy.cfg"}
HAPROXY_PORTS=${HAPROXY_PORTS:-"80,443"}

HAPROXY_PID_FILE="/var/run/haproxy.pid"
HAPROXY_CMD="sudo /usr/local/sbin/haproxy -f ${HAPROXY_CONFIG} -p ${HAPROXY_PID_FILE}"
HAPROXY_CHECK_CONFIG_CMD="/usr/local/sbin/haproxy -c -- ${HAPROXY_CONFIG}"

function safe_run {
  if [[ ! -f "${HAPROXY_CONFIG}" ]]; then
    echo "No config.." >&2
    exit 1
  fi

  ${HAPROXY_CHECK_CONFIG_CMD} && RC=0 || RC=1
  if [[ ${RC} -ne 0 ]]; then
    notify
  else
    ${ENABLE_SYN_DROP}
    sleep 0.2
    if [[ -f "${HAPROXY_PID_FILE}" ]]; then
      ${HAPROXY_CMD} -sf $(cat ${HAPROXY_PID_FILE})
    else
      ${HAPROXY_CMD}
    fi
    ${DISABLE_SYN_DROP}
    notify
  fi
}

function notify {
  if [[ ${RC} -ne 0 ]]; then
    echo "${HAPROXY_INVALID_MSG}" >&2
  else
    echo "${HAPROXY_VALID_MSG}"
  fi

}