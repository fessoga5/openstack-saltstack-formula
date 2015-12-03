# vim: sts=2 ts=2 sw=2 et ai
{% from "openstack/compute/map.jinja" import openstack with context %}
{% from "openstack/compute/defaults.jinja" import computeversion with context %}
{% set compute = computeversion.get(openstack.version, {}) %}

openstack-apt:
  pkgrepo.managed:
    - humanname: 'Openstack PPA'
    - name: {{ openstack.get("openstack-repo") }}
    - dist: trusty-updates/{{ openstack.version }}
    - file: /etc/apt/sources.list.d/cloudarchive.list

openstack-install:
  pkg.installed:
    - name: ubuntu-cloud-keyring


#Configure files
install-neutron-plugin:
  pkg.installed:
    - pkgs:
      - neutron-plugin-ml2
      - neutron-plugin-openvswitch-agent

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
    - source: salt://openstack/compute/files/{{ openstack.version }}/general.jinja
    - user: nova
    - group: nova
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.nova }}

"/etc/nova/nova-compute.conf":
  file.managed:
    - source: salt://openstack/compute/files/{{ openstack.version }}/general.jinja
    - user: nova
    - group: nova
    - mode: 644
    - template: jinja
    - context:
        data: {{ compute.get("nova-compute") }}


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
      - python-pip
  file.managed:
    - name: /etc/default/docker
    - source: salt://openstack/compute/files/{{ openstack.version }}/docker
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
    - name: {{ compute.novadocker.repo }} 
    - rev: {{ compute.novadocker.revision }}
    - target: /opt/novadocker
    - require:
      - pkg: docker-openstack
  cmd.run:
    - name: |
        usermod -aG docker nova; cd /opt/novadocker; python setup.py install
    - require:
      - git: docker-openstack

#running nova compute
nova-compute:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nova/nova-compute.conf
      - file: /etc/nova/nova.conf
    - require:
      - service: docker-openstack
#
#install_ceph_raid:
#  pkg.installed:
#    - name: ceph
#    - forceyes: True
#  file.managed:
#    - name: /etc/ceph/rbdmap
#    - source: salt://openstack/compute/files/rbdmap
#    - user: root
#    - group: root
#    - mode: 644
#    - makedirs: True
#    - context:
#        data: {{ compute }}
#  service.running:
#    - name: rbdmap
#    - enable: True
#    - reload: True
#    - watch:
#      - file: /etc/ceph/rbdmap
#
#

