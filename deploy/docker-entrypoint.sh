#!/bin/sh
# Docker 镜像入口：把历史 CMD/healthcheck 的 /renewlet 稳定路径桥接到可替换真实二进制。
# 触发时机：容器启动；依赖 su-exec、/pb_data volume 和 /opt/renewlet/current/renewlet。
set -e

if [ "$#" -eq 0 ]; then
  set -- /renewlet
elif [ "${1#-}" != "$1" ]; then
  set -- /renewlet "$@"
elif [ "$1" = "serve" ] || [ "$1" = "superuser" ] || [ "$1" = "healthcheck" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  set -- /renewlet "$@"
fi

if [ "$(id -u)" = "0" ]; then
  mkdir -p /pb_data /opt/renewlet/current /opt/renewlet/backups
  # /renewlet 是旧 compose/healthcheck 的稳定入口；真实可替换二进制固定在 current/renewlet。
  if [ -e /renewlet ] && [ ! -L /renewlet ]; then
    rm -f /renewlet
  fi
  if [ ! -e /renewlet ]; then
    ln -s /opt/renewlet/current/renewlet /renewlet
  fi
  chown -R renewlet:renewlet /pb_data /opt/renewlet

  if [ "$1" = "/renewlet" ]; then
    # 默认 server 进程降权运行；显式执行其它命令时保留用户选择，方便调试/维护容器。
    exec su-exec renewlet "$@"
  fi
fi

exec "$@"
