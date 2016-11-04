1、共检查6个服务，分别对应6个命令：
service neutron-server status
service neutron-dhcp-agent status
service neutron-l3-agent status
service neutron-openvswitch-agent status
service neutron-lbaas-agent status
service neutron-metadata-agent status
2、控制节点上检查命令neutron agent-list结果，需要在配置文件中增加环境变量配置，以导入admin-openrc
3、第1条中6个命令由shell脚本和py脚本组成,shell脚本实现命令执行，py脚本封装以供通用组调用(通用组后来不支持直接调用sh脚本，所以采用py封装一层)，每个py脚本内容一样，只有名称不同，因为通用组件调用时是使用import py脚本名实现，每个服务需要一个py脚本。
4、第2条的命令直接用py脚本编写。如果以后新增命令可参考该脚本实现，只写py脚本即可。
5、脚本部署由通用组实现。
