#!/bin/sh
set -e

# Запускаем Tailscale в фоне
/usr/local/bin/tailscale.sh &

# Небольшая пауза на инициализацию (опционально)
/bin/sleep 1

# Передаём управление 3proxy
exec /usr/local/bin/3proxy /etc/3proxy/3proxy.cfg
