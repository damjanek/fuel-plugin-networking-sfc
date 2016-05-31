#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

notice('MODULAR: networking-sfc/networking-sfc-controller.pp')

$primary_controller = hiera('primary_controller')

service {'neutron-openvswitch-agent':
  ensure    => running,
  enable    => true,
  hasstatus => true,
}

service {'neutron-server':
  ensure    => running,
  enable    => true,
  hasstatus => true,
}

package{ 'git':
  ensure => present,
} ->
vcsrepo { '/root/networking-sfc':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/openstack/networking-sfc.git',
} ->
exec { 'install sfc':
  command => 'python setup.py install',
  path    => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
  cwd     => '/root/networking-sfc',
  creates => '/usr/local/lib/python2.7/dist-packages/networking_sfc'
}

if $primary_controller {
  exec { 'Schema upgrade for SFC':
    command => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --subproject networking-sfc upgrade head && touch /usr/local/sfc_schema_changed',
    path    => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
    creates => '/usr/local/sfc_schema_changed'
  } -> Exec ['Modify neutron.conf'] -> Exec ['Modify neutron-openvswitch-agent.conf']
}
# TODO: replace it with something less ugly
exec { 'Modify neutron.conf':
  command => "sed -i '/^service_plugins/ s/$/,networking_sfc.services.flowclassifier.plugin.FlowClassifierPlugin,networking_sfc.services.sfc.plugin.SfcPlugin/' /etc/neutron/neutron.conf && echo '\n[sfc]\ndrivers = ovs\n' >> /etc/neutron/neutron.conf && touch /usr/local/sfc_configured",
  path    => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
  creates => '/usr/local/sfc_configured',
} ->
# TODO: same here
exec { 'Modify neutron-openvswitch-agent.conf':
  command => "sed -i 's|/usr/bin|/usr/local/bin|g' /etc/init/neutron-openvswitch-agent.conf && touch /usr/local/sfc_configured2",
  path    => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
  creates => '/usr/local/sfc_configured2',
  notify  => [Service['neutron-openvswitch-agent'],Service['neutron-server']],
}
