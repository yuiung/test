pg_monz_win 2.0
============================
pg_monz (PostgreSQL monitoring template for Zabbix) is a Zabbix template for
monitoring PostgreSQL. It enables various types of monitoring of PostgreSQL
such as alive, resource, performance, etc.
Pg_monz also supports automatic discovery of databases and tables using the
discovery feature of Zabbix and can automatically start monitoring.


Changes from 1.0
----------------
The following is a summary of the major changes.


### Support for monitoring of PostgreSQL Streaming Replication
pg_monz 2.0 now supports monitoring of Streaming Replication which is embedded in PostgreSQL since 9.0.  
Various monitoring items such as Primary / Standby servers alive monitoring, delay of replication data propagation and conflicts occurred by operation to Primary and Standby are available.
It is also that a trigger which can detect the occurence of write block query when useing synchronous replication is provided.

### Group items
Monitoring items are grouped by each application to clarify them.  
The following are main applications.


#### Applications | PostgreSQL
|application name   |summary of monitoring                                                                            |
|:------------------|-------------------------------------------------------------------------------------------------|
|pg.transactions    |Connection count, state to PostgreSQL, the number of commited, rolled back transactions          |
|pg.log             |log monitoring for PostgreSQL                                                                    |
|pg.size            |garbage ratio, DB size                                                                           |
|pg.slow_query      |slow query count which exceeds the threshold value                                               |
|pg.sr.status       |conflict count, write block existence or non-existence, process count using Streaming Replication|
|pg.status          |PostgreSQL processes working state                                                               |
|pg.stat_replication|delay of replication data propagation using Streaming Replication                                |
|pg.cluster.status  |PostgreSQL processes count as a cluster                                                          |





### Improve performance of gathering monitoring items
Previously, pg_monz accesses the monitoring DB every when gathering one monitoring item about DB, which may affect the performance of monitoring DB.
With this update, to reduce the frequency of DB accesse, pg_monz gathers collectable monitoring items all at once.


System requirements
-------------------
pg_monz requires the following software products:

* Zabbix server, zabbix agent, zabbix sender 2.0 or later
* PostgreSQL 9.2 or later


Installation and usage
----------------------
Please see the included quick-install.txt.  
pg_monz 2.0 does not have backward compatibility with the 1.0. When upgrading from 1.0, please install the new version again.


License
-------
pg_monz is distributed under the Apache License Version 2.0.
See the LICENSE file for details.
  
Copyright (C) 2013-2016 TIS Inc. All Rights Reserved.
