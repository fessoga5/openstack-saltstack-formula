# vim: sts=2 ts=2 sw=2 et ai
{% from "openstack/compute/map.jinja" import openstack with context %}
{% from "openstack/compute/defaults.jinja" import compute with context %}

#Configure forwarding
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 0

net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 0

#Install apts
openstack-apt:
  pkgrepo.managed:
    - humanname: 'Openstack PPA'
    - name: {{ openstack.get("openstack-repo") }}
    - dist: trusty-updates/{{ openstack.version }}
    - file: /etc/apt/sources.list.d/cloudarchive.list

openstack-install:
  pkg.installed:
    - name: ubuntu-cloud-keyring


#Configure Neutron
install-neutron-plugin:
  pkg.installed:
    - pkgs:
      - neutron-plugin-ml2
      - neutron-plugin-openvswitch-agent
      - neutron-l3-agent 
      - neutron-dhcp-agent 
      - neutron-metadata-agent

configure-neutron:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: salt://openstack/compute/files/{{ openstack.version }}/neutron.conf
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.neutron }}

# ml2 plugin
configure-ml2-plugin:
  file.managed:
    - name: /etc/neutron/plugins/ml2/ml2_conf.ini
    - source: salt://openstack/compute/files/{{ openstack.version }}/ml2_conf.ini
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.ml2_conf }}

"neutron-plugin-openvswitch-agent":
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini


# L3 agent
"neutron-l3-agent":
  file.managed:
    - name: /etc/neutron/l3_agent.ini
    - source: salt://openstack/compute/files/{{ openstack.version }}/l3_agent.ini
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.l3_agent }}
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/l3_agent.ini

#  DHCP agent
"neutron-dhcp-agent":
  file.managed:
    - name: /etc/neutron/dhcp_agent.ini
    - source: salt://openstack/compute/files/{{ openstack.version }}/dhcp_agent.ini
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.dhcp_agent }}
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/dhcp_agent.ini

#  DHCP agent
"neutron-metadata-agent":
  file.managed:
    - name: /etc/neutron/metadata_agent.ini
    - source: salt://openstack/compute/files/{{ openstack.version }}/metadata_agent.ini
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.metadata_agent }}
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/metadata_agent.ini

# Manual command
#ovs-vsctl add-br br-ex
#ovs-vsctl add-port br-ex INTERFACE_NAME
#ethtool -K INTERFACE_NAME gro off

# OpenvSwitch
openvswitch-switch:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini  
