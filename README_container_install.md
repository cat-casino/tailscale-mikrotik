#### Включить container mode, если ещё не включён
```sh
/system device-mode update container=yes
```

#### Настройка veth/моста/маршрутов (пример — уже есть в твоей конфигурации, можно пропустить если настроено)
#### Создание интерфейса veth для tailscale
/interface veth add name=vtailscale address=172.17.0.2/16 gateway=172.17.0.1

##### Настройка bridge для btailscale (если нужно, в исходной конфигурации был btailscale)
```sh
/interface bridge add name=btailscale
/ip address add address=172.17.0.1/16 interface=btailscale
/interface bridge port add bridge=btailscale interface=vtailscale
```

#### Добавление маршрута к рекламе subnet через контейнер
```sh
/ip route add dst-address=100.64.0.0/10 gateway=172.17.0.2
```

#### Создание envlist и переменных окружения
```sh/container envs
add name="tailscale" key="PASSWORD" value="root"
add name="tailscale" key="AUTH_KEY" value="39dba59a5d70c65ea4d60a60a76451437b5e97d5aa29ed60"
add name="tailscale" key="ADVERTISE_ROUTES" value="192.168.88.0/24"
add name="tailscale" key="CONTAINER_GATEWAY" value="172.17.0.1"
add name="tailscale" key="UPDATE_TAILSCALE" value=""
add name="tailscale" key="TAILSCALE_ARGS" value="--login-server=https://vpn.cp.nextcode.tech --accept-routes --advertise-routes=192.168.88.0/24 --advertise-exit-node --netfilter-mode=off"
```
#### Настройка реестра (GHCR)
```sh
/container config set registry-url=https://ghcr.io tmpdir=usb1/docker/tmp layer-dir=usb1/docker/layers
```
#### Создание монтирования состояния tailscale (если ещё не создано)
#### Предполагается, что каталог для хранения есть: /usb1/docker/tailscale
#### Название монтa — ts-state, монтируется в /var/lib/tailscale внутри контейнера
```sh
/container mounts
add name=ts-state src=/usb1/docker/tailscale dst="/var/lib/tailscale"
```
#### Добавление контейнера из удалённого образа
```sh
/container add remote-image=ghcr.io/fluent-networks/tailscale-mikrotik:latest interface=vtailscale envlist=tailscale root-dir=usb1/docker/root-ts mounts=ts-state start-on-boot=yes hostname=mikrotik dns=8.8.4.4,8.8.8.8 logging=yes
```
#### Запуск контейнера
```sh 
/container start 0
```