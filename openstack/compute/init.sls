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
docker-openstack:
  pkgrepo.managed:
    - humanname: Docker PPA
    - name: deb https://get.docker.com/ubuntu docker main 
    - dist: docker
    - file: /etc/apt/sources.list.d/docker.list
    #- keyid: 
    #- keyserver: keyserver.ubuntu.com
  pkg.installed:
    - forceyes: True
    - pkgs:
      - lxc-docker-1.7.1
      - git
  file.managed:
    - name: /etc/default/docker
    - source: salt://openstack/compute/files/docker
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute }}
  service.running:
    - name: docker
    - enable: True
    - reload: True
    - watch: 
      - file: /etc/default/docker
  git.latest:
    - name: http://gitlab01.core.irknet.lan/devops/novadocker.git 
    - target: /opt
    - require:
      - pkg: docker-openstack
      - ssh_known_hosts: gitlab01.core.irknet.lan
  ssh_known_hosts:
    - name: gitlab01.core.irknet.lan
    - present
    - user: root
    - enc: ecdsa
    - fingerprint: 03:2f:e3:b7:57:a8:12:de:a7:5f:51:4a:21:b3:ff:c6  
  cmd.run:
    - name: |
        cd /opt/novadocker && python setup.py install
    - require:
      - git: docker-openstack

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
    - name: ceph
    - forceyes: True
  file.managed:
    - name: /etc/ceph/rbdmap
    - source: salt://openstack/compute/files/rbdmap
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - context:
        data: {{ compute }}
  service.running:
    - name: rbdmap
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ceph/rbdmap
#
#

