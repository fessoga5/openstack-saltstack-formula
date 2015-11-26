# vim: sts=2 ts=2 sw=2 et ai
{% from "openstack/compute/map.jinja" import openstack with context %}
{% set compute = pillar.get('openstack').compute  %}

kilo-apt:
  pkgrepo.managed:
    - humanname: Openstack PPA
    - name: deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main
    - dist: trusty-updates/kilo
    - file: /etc/apt/sources.list.d/cloudarchive-kilo.list

kilo-install:
  pkg.installed:
    - name: ubuntu-cloud-keyring

# install and configure docker
docker-apt:
  pkgrepo.managed:
    - humanname: Docker PPA
    - name: deb https://get.docker.com/ubuntu docker main 
    - dist: docker
    - file: /etc/apt/sources.list.d/docker.list
    #- keyid: 
    #- keyserver: keyserver.ubuntu.com
  pkg.installed:
    - forceyes: True
    - name: lxc-docker-1.7.1
  service.running:
    - name: docker
    - enable: True
    - reload: True
    - watch: 
      - file: /etc/default/docker

#compute-install-packages:
#  pkg.installed:
#    - forceyes: True
#    - pkgs:
#      - nova-compute 
#      - sysfsutils
#      - lxc-docker-1.7.1
#      - neutron-plugin-ml2
#      - neutron-plugin-openvswitch-agent

#Configure files
install-neutron-plugin:
  pkg.installed:
    - pkgs:
      - neutron-plugin-ml2
      - neutron-plugin-openvswitch-agent

configure-neutron:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: salt://openstack/compute/files/neutron.conf
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute }}

configure-ml2-plugin:
  file.managed:
    - name: /etc/neutron/plugins/ml2/ml2_conf.ini
    - source: salt://openstack/compute/files/ml2_conf.ini
    - user: neutron
    - group: neutron
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute }}

"neutron-plugin-openvswitch-agent":
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini

openvswitch-switch:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini  


# Nova compute install and configure 
novacompute-install:
  pkg.installed:
    - forceyes: True
    - name: nova-compute 

"/etc/nova/nova.conf":
  file.managed:
    - source: salt://openstack/compute/files/nova.conf
    - user: nova
    - group: nova
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute }}

"/etc/nova/nova-compute.conf":
  file.managed:
    - source: salt://openstack/compute/files/nova-compute.conf
    - user: nova
    - group: nova
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute }}

nova-compute:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nova/nova-compute.conf
      - file: /etc/nova/nova.conf

#
install_ceph_raid:
  pkg.installed:
    - name: sysfsutils
    - forceyes: True
  file.managed:
    - name: /etc/ceph/rbdmap
    - source: salt://openstack/compute/files/rbdmap
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - watch:
      - file: /etc/ceph/rbdmap
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ceph/rbdmap
#
#novadocker:
#  cmd.run:
#    - name: |
#        cd /opt && git clone http://gitlab01.core.irknet.lan/devops/novadocker.git && cd novadocker && python setup.py install
#

