# 1. Удаляем старый tmpfs-диск tmp1, если он есть
/disk remove [find name="tmp1"]

# 2. Создаём новый tmpfs-диск 200M
/disk add type=tmpfs name=tmp1 tmpfs-max-size=200M

# 3. Перенастраиваем кеш контейнера в RAM
/container config set registry-url=https://registry-1.docker.io tmpdir=tmp1/tmp layer-dir=tmp1/layers

# 4. Останавливаем и удаляем старый контейнер (индекс 0, или найдите актуальный через /container print)
/container stop 0
/container remove 0

# 5. Пересоздаём маунт состояния
/container mounts remove [find name="local-ts-state"]
/container mounts add name=local-ts-state src=tmp1/local-ts-state dst="/var/lib/tailscale"

# 6. Очищаем старые envs и добавляем свежие
/container envs remove [find name="tailscale"]
/container envs add name="tailscale" key="PASSWORD" value="root"
/container envs add name="tailscale" key="AUTH_KEY" value="tskey-<ваш ключ>"
/container envs add name="tailscale" key="ADVERTISE_ROUTES" value="0.0.0.0/0"
/container envs add name="tailscale" key="CONTAINER_GATEWAY" value="172.17.0.1"
/container envs add name="tailscale" key="UPDATE_TAILSCALE" value=""
/container envs add name="tailscale" key="TAILSCALE_ARGS"  value="--accept-routes --advertise-exit-node"
/container envs add name="tailscale" key="LOGIN_SERVER" value="https://vpn.cat-infra.pp.ua"

# 7. Добавляем и запускаем новый контейнер полностью в RAM
/container add remote-image=psleo/tailscale-mikrotik:aarch64-nosquash \
  interface=vtailscale \
  envlist=tailscale \
  root-dir=tmp1/local-root-ts \
  mounts=local-ts-state \
  start-on-boot=yes \
  hostname=mikrotik \
  dns=8.8.4.4,8.8.8.8 \
  logging=yes

/container start 0
