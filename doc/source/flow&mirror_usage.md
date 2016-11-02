[TOC]
###flowtool mirrortool脚本使用说明
####flowtool
输出命令总的帮助信息
```bash
# flowtool -h
usage: flowtool [-h]
{sflow-create,sflow-delete,sflow-list,netflow-create,netflow-delete,netflow-list}
                ...

flowtool is used for manage sflow or netflow on ovs
create_sflow example:
---------
flowtool sflow-create eth0 192.168.1.12:6345 br-int
---------

create_netflow example:
---------
sflowtool netflow-create 192.168.1.12:5566 br-int
---------

positional arguments:
  {sflow-create,sflow-delete,sflow-list,netflow-create,netflow-delete,netflow-list}
    sflow-create        create slfow on ovs bridge
    sflow-delete        delete sflow on ovs bridge
    sflow-list          list sflow
    netflow-create      create netflow
    netflow-delete      delete netflow on ovs bridge
    netflow-list        list netfow

optional arguments:
  -h, --help            show this help message and exit
```
#####创建sflow
```bash
# flowtool sflow-create -h
usage: flowtool sflow-create [-h] [--header HEADER] [--sampling SAMPLING]
                             [--polling POLLING]
                             agent target bridge

positional arguments:
  agent                interface which sends sflow ,like eth0
  target                ip:port where slfow is received
  bridge               bridge on which setup sflow

optional arguments:
  -h, --help           show this help message and exit
  --header HEADER      default:128
  --sampling SAMPLING  default:5
  --polling POLLING    default:5
```
例：
```bash
# flowtool sflow-create enp0s8 192.168.56.1:6345 br-int
192.168.56.1:6345 sflow远端分析器的地址和端口
enp0s8：通过该设备向192.168.56.1:6345发送sflow报文
br-int：需要设置sflow-agent的ovs网桥
不使用默认值的情况：
#  flowtool sflow-create enp0s8 192.168.56.1:6345 br-int --header 256 --sampling 10 --polling 10
```
#####列出sflow
```bash
# flowtool sflow-list
_uuid               : 87bd182a-ab0b-4337-a5b1-a98da17cb695
agent               : "enp0s8"
external_ids        : {}
header              : 256
polling             : 10
sampling            : 10
targets             : ["192.168.56.1:6345"]
```
#####删除sflow
```bash
# flowtool sflow-delete -h
usage: flowtool sflow-delete [-h] bridge

positional arguments:
  bridge      bridge on which remove sflow

optional arguments:
  -h, --help  show this help message and exit
```
例:
```bash
# flowtool sflow-delete br-int
```
#####创建netflow
```bash
flowtool netflow-create -h
usage: flowtool netflow-create [-h] [--timeout TIMEOUT] bridge target

positional arguments:
  bridge             bridge on which setup netflow
  target             ip:port where netflow is received

optional arguments:
  -h, --help         show this help message and exit
  --timeout TIMEOUT  default:30
```
例:
```bash
# flowtool netflow-create br-int 192.168.57.1:6666
192.168.56.1:6666 netflow远端分析器的地址和端口
br-int 需要设置netflow的ovs网桥
```
#####列出netflow
```bash
# flowtool netflow-list
_uuid               : 9170a342-c81a-4d6a-a9c4-38a650e70bec
active_timeout      : 30
add_id_to_interface : false
engine_id           : []
engine_type         : []
external_ids        : {}
targets             : ["192.168.57.1:6666"]
```
#####删除netflow
```bash
# flowtool netflow-delete -h
usage: flowtool netflow-delete [-h] bridge

positional arguments:
  bridge      bridge on which remove netflow

optional arguments:
  -h, --help  show this help message and exit
```
例：
```bash
# flowtool netflow-delete br-int
```

####mirrortool
输出命令总的帮助信息
```bash
# mirrortool -h
usage: mirrortool [-h] {mirror-create,mirror-delete,mirror-list} ...

mirrortool is used for setting port mirror on ovs
create port mirror example
--------
mirrortool mirror-create br-int qvoe803d7e9-90 foo
--------
delete port mirror example
--------
mirrortool mirror-delete br-int foo
--------

positional arguments:
  {mirror-create,mirror-delete,mirror-list}
    mirror-create       create port mirror on ovs
    mirror-delete       delete port mirror on ovs
    mirror-list         list port mirror on ovs

optional arguments:
  -h, --help            show this help message and exit
```
#####创建mirror
```bash
# mirrortool mirror-create -h
usage: mirrortool mirror-create [-h] bridge port name

positional arguments:
  bridge      bridge on which setup port mirror
  port        port which needed to be mirrored
  name        mirror's name

optional arguments:
  -h, --help  show this help message and exi
```
例:
```bash
# mirrortool mirror-create br-int qr-2a17cfcc-c0 foo
br-int 需要设置端口镜像的网桥
port 需要被mirror的端口
foo 名称
命令输出
7fc5b639-89c0-4857-8a64-5849ab6f178f

Now you can tcpdump interface mir-foo-a
```
#####列出mirror
```bash
# mirrortool mirror-list
_uuid               : 7fc5b639-89c0-4857-8a64-5849ab6f178f
external_ids        : {}
name                : foo
output_port         : 6121cd80-25af-45ac-a601-f5a0ef455f14
output_vlan         : []
select_all          : false
select_dst_port     : [5aa7a420-e5aa-4c06-9cf4-a95f55fe4346, d6ea342b-cf27-44a7-8493-99fff4aa2080]
select_src_port     : [5aa7a420-e5aa-4c06-9cf4-a95f55fe4346, d6ea342b-cf27-44a7-8493-99fff4aa2080]
select_vlan         : []
statistics          : {tx_bytes=74348, tx_packets=774}
```
#####删除mirror
```bash
mirrortool mirror-delete -h
usage: mirrortool mirror-delete [-h] bridge name

positional arguments:
  bridge      bridge on which delete port mirror
  name        mirror's name

optional arguments:
  -h, --help  show this help message and exit
```
例：
```bash
# mirrortool mirror-delete br-int foo
```

