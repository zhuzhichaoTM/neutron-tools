#!/bin/bash

if [ "$FW"  ];then
	return
fi
export FW="fw.sh"

fw_setup() {
	#create fw policy, rule, then bind router
        neutron firewall-policy-create "fw-policy-$j-$j-1"
        neutron firewall-policy-create "fw-policy-$j-$j-2"
        neutron firewall-rule-create --name "fw-rule-$j-$i-1" --protocol tcp  --action allow
        neutron firewall-rule-create --name "fw-rule-$j-$i-2" --protocol tcp  --action allow
        neutron firewall-policy-insert-rule "fw-policy-$j-$i-1" "fw-rule-$j-$i-1"
        neutron firewall-policy-insert-rule "fw-policy-$j-$i-2" "fw-rule-$j-$i-2"
        neutron firewall-create --name "fw-firewall-$j-$i-1" --router "router-$j-$i" "fw-policy-$j-$i-1"
        neutron firewall-delete "fw-firewall-$j-$i-1"
        neutron firewall-create --name "fw-firewall-$j-$i-2" --router "router-$j-$i" "fw-policy-$j-$i-2"
}

fw_cleanup() {
	#delete firewall policy, rule, firewall
	firewalls=`neutron firewall-list | grep fw-firewall | awk -F'|' '{print $2}' | grep -v '^$'`
	for firewall in $firewalls;
	do
        	neutron firewall-delete $firewall
	done

	policys=`neutron firewall-policy-list | grep fw-policy | awk -F'|' '{print $2}' | grep -v '^$'`
	for policy in $policys;
	do
        	neutron firewall-policy-delete $policy
	done

	#firewall policy depend on firewall rule, so firewall should be deleted first
	rules=`neutron firewall-rule-list | grep fw-rule | awk -F'|' '{print $2}' | grep -v '^$'`
	for rule in $rules;
	do
        	neutron firewall-rule-delete $rule
	done
}
