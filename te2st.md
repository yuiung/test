pg_monz_win 2.0
  |
|:------------------|-------------------------------------------------------------------------------------------------|
|pg.transactions    |Connection count, state to PostgreSQL, the number of commited, rolled back transactions          |
|pg.log             |log monitoring for PostgreSQL                                                                    |
|pg.size            |garbage ratio, DB size                                                                           |
|pg.slow_query      |slow query count which exceeds the threshold value                                               |
|pg.sr.status       |conflict count, write block existence or non-existence, process count using Streaming Replication|
|pg.status          |PostgreSQL processes working state                                                               |
|pg.stat_replication|delay of replication data propagation using Streaming Replication                                |
|pg.cluster.status  |PostgreSQL processes count as a cluste                方法无法vfwavavdagedddfajdfhoriojjiourijerkl我我按计划覅ifif啊哈覅UI唯一认可你咳嗽哦 结婚卡号花蝴蝶会恢复加肥加大 i惊世毒妃南大街哈候机飞蝗芜湖恢复加的话费覅uh9看门禁客户服务赫尔是UK自己看速度快回复函




电话费 安抚欧尼HiFi按防护乳aura开心伐接口r8ibaohfee8r官方库ijew恩恩 呼呼jhxfj好发辅导员 的r                                                          |





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
  
Copyright (C) 2013-2016 TIS Inc. All Rights Reserved.pg_monz 2.0 does not have backward compatibility with the 1.0. When upgrading from 1.0, please install the new version again.


License
-------
pg_monz is distributed under the Apache License Version 2.0.
See the LICENSE file for details.
  
Copyright (C) 2013-2016 TIS Inc. All Rights Reserved.
