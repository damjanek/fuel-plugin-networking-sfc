Networking SFC plugin for Fuel
=======================

Networking SFC
--------------

One of the foundations for NFV enabled clouds is to have
Networking Service Function Chaining which provides an
ability to define an ordered list of network services
which to form a “chain” of services. This could be used
by f.e. Telcos to simplify management of their infrastructure.

This plugin extends MOS with Networking SFC.

Requirements
------------

| Requirement                      | Version |
|:---------------------------------|:--------|
| Mirantis OpenStack compatibility | 9.0     |

Known Issues
-------------------
It is required to install this on vxlans enabled environment. Will not work otherwise.
You need to perform following command after plugin installation on primary controller:
```
neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --subproject networking-sfc upgrade head
```


Contributors
------------

Damian Szeluga <dszeluga@mirantis.com> (developer)
Maciej Relewicz <mrelewicz@mirantis.com> (developer)
