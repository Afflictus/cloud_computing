#!/bin/bash
if [ -n "$1" ]; then

#Установка доп. пакетов
apt install vlan bridge-utils net-tools

#Включаем VLAN
modprobe 8021q

#Включаем форвардинг пакетов
#Нужен, чтобы использовать хост как маршрутизатор или интернет-шлюз
sysctl -w net.ipv4.conf.default.forwarding=1
sysctl -w net.ipv4.ip_forward=1

#Создаем namespaces
#netns - network namespace
ip netns add h2
ip netns add h3
ip netns add h4

#Создаем интерфейсы для связи каждого из неймспейсов с хостом
#Левая часть помещается в namespace, а правая в bridge
#ip link add DEVICE type { veth | vxcan } [ peer name NAME ]
#peer name NAME - specifies the virtual pair device name of the VETH/VXCAN tunnel.
#peer name NAME - указывает имя устройства виртуальной пары
ip link add v_l_h2 type veth peer name v_h2
ip link add v_l_h3 type veth peer name v_h3
ip link add v_l_h4 type veth peer name v_h4

#Добавляем левые части в namespace'ы
ip link set v_l_h2 netns h2
ip link set v_l_h3 netns h3
ip link set v_l_h4 netns h4

#Делаем левые части активными
ip netns exec h2 ip link set v_l_h2 up
ip netns exec h3 ip link set v_l_h3 up
ip netns exec h4 ip link set v_l_h4 up

#Добавляем VLAN ВНУТРИ неймспейсов
#ip link add link DEVICE name NAME type vlan
ip netns exec h2 ip link add link v_l_h2 name v_2_10 type vlan id 10
ip netns exec h2 ip link add link v_l_h2 name v_2_20 type vlan id 20
ip netns exec h3 ip link add link v_l_h3 name v_3_10 type vlan id 10
ip netns exec h4 ip link add link v_l_h4 name v_4_20 type vlan id 20

#Присваиваем адреса и активируем интерфейсы внутри неймспейсов
ip netns exec h2 ifconfig v_2_10 10.0.0.2/24 up
ip netns exec h2 ifconfig v_2_20 20.0.0.2/24 up
ip netns exec h3 ifconfig v_3_10 10.0.0.3/24 up
ip netns exec h4 ifconfig v_4_20 20.0.0.4/24 up

#Активируем интерфейс lo, чтобы пакеты проходили к локальному адресу неймспейса
ip netns exec h2 ip link set lo up
ip netns exec h3 ip link set lo up
ip netns exec h4 ip link set lo up

#Создаем и активируем мост
brctl addbr br0
ip link set br0 up

#Добавляем в мост ПРАВЫЕ части трубы и активируем их
brctl addif br0 v_h2
brctl addif br0 v_h3
brctl addif br0 v_h4
ip link set v_h2 up
ip link set v_h3 up
ip link set v_h4 up

#Добавляем VLAN ВНУТРИ моста
ip link add link br0 name br0_10 type vlan id 10
ip link add link br0 name br0_20 type vlan id 20

#Присваиваем адреса и активируем интерфейсы моста
ifconfig br0_10 10.0.0.1/24 up
ifconfig br0_20 20.0.0.1/24 up

#Добавляем маршруты до конкретных адресов в неизвестных неймспейсам сетях
ip netns exec h4 ip route add 10.0.0.2 dev v_4_20
ip netns exec h4 ip route add 10.0.0.1 dev v_4_20
ip netns exec h3 ip route add 20.0.0.1 dev v_3_10
ip netns exec h3 ip route add 20.0.0.2 dev v_3_10

#Добавляем маршруты по умолчанию (до всех остальных адресов во всех сетях) для неймспейсов
ip netns exec h2 ip route add default via 20.0.0.1
ip netns exec h3 ip route add default via 20.0.0.1
ip netns exec h4 ip route add default via 10.0.0.1

#-t - задает таблицу, к которой будет применена команда
#nat - используется, когда встречается пакет, устанавливающий новое соединение.
#-A - добавить правило
#POSTROUTING - для всех изменения всех исходящих пакетов
#-o - имя интерфейса, через который отправляется обрабатываемый пакет (для POSTROUTING)
#-j - определяет цель правила, т. е., что делать, когда пакет попадает под условия правила
#MASQUERADE - цель допустима только в таблице nat в цепочке POSTROUTING
#Маскардинг - по сути привязывание к IP-адресу интерфейса, через который пакет выходит
iptables -t nat -A POSTROUTING -o $1 -j MASQUERADE

else
echo "[ network interface ]"
fi