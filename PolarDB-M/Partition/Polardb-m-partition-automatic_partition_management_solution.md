<a name="Q6Yf8"></a>
# Partition Feature 2: Automatic Partition Management Solution
The automatic partition management solution of PolarDB MySQL can help customers reduce costs and increase efficiency.
<a name="O2ulw"></a>
## Business Scenario
Assuming that the PolarDB MySQL is now used as a data transfer station, the data generated in the business every day will be stored in a new partition of the database, and then the data will be synchronized to the data warehouse for analysis at the same time. After the synchronization, the data in the partition can be clean up. During the O&M time of the next day, the partition where the data of the previous day is located can be dropped to save disk space, which can achieve the purpose of reducing costs and increasing efficiency.<br />In this scenario, the advantage of using the PolarDB MySQL partition table is that, due to the support of the new features of partition level mdl and interval partitioning, droppping old partitions and adding new ones will not block the DML operation of the current partition.<br />![image.png](https://intranetproxy.alipay.com/skylark/lark/0/2022/png/221080/1672284218593-741acd27-e685-4898-adbb-fe17e90354c4.png#clientId=ub7df047b-4c00-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=645&id=u9b51b0f9&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1290&originWidth=2126&originalType=binary&ratio=1&rotation=0&showTitle=false&size=771421&status=done&style=none&taskId=u318de479-eab7-40d4-8682-8f7297bb3ae&title=&width=1063)
<a name="BfKoy"></a>
## The Solution
On the [PolarDB console](https://polardb.console.aliyun.com/), select an instance whose cluster version must be PolarDB MySQL engine version 8.0.2 and whose Revision version is 8.0.2.2.0 or above. If there is no suitable instance, please purchase a new instance or upgrade the instance version.
<a name="bm6RF"></a>
### Parameters
PolarDB MySQL has a new feature of partition level mdl, which can reduce the granularity of MDL to optimize some scenarios where DDL and DML are mutually blocked. Enable this function to better experience automatic partition management.<br />On the navigation interface of the instance, click **Parameters**, enter partition_level_mdl_enabled in the input box, and check the value of this parameter. If the current value is not **ON**, you need to modify the parameter to **ON** on the console.<br />**Steps:**

1. Click **Modify**.
2. Search partition_level_mdl_enabled.
3. If the **Cluster Parameter** column shows that the current value is **OFF**, click the button to change it to **ON.**
4. Click **Apply Changes**.
5.  Click **Modify Now**.

Modifying this parameter requires restarting the instance. After the instance restarts, click **Log On to Database** to create events on the DMS console.
<a name="hfpEM"></a>
### Events
Adding/dropping partitions periodically through events can reduce the workload of the DBA.<br />First create an Interval partition table, `gmt_create` as the partition key, the interval is 1 day, and there is a partition p0 in the table.
```sql
CREATE TABLE `xxx_metering` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `gmt_create` datetime NOT NULL COMMENT '创建时间',
  `uid` varchar(128) NOT NULL COMMENT 'uid',
  `gmt_modified` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'modified time',
  `count` int(10) unsigned DEFAULT NULL,
  `type` varchar(32) DEFAULT NULL COMMENT '(Normal, Warning)',
  PRIMARY KEY (`id`, `gmt_create`),
  KEY `idx_gmt_create` (`gmt_create`),
  KEY `idx_gmt_modified` (`gmt_modified`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
PARTITION BY RANGE COLUMNS(`gmt_create`) INTERVAL(DAY,1)
(
  PARTITION p0 VALUES LESS THAN('2022-12-27')
);
```
At present, the largest partition range is '2022-12-27', insert some data beyond the partition range, and the interval partition will automatically add partitions.
```sql
INSERT INTO xxx_metering VALUES(0, '2022-12-27', '0', '2022-12-27', 1, 'Normal');
INSERT INTO xxx_metering VALUES(0, '2022-12-28', '0', '2022-12-28', 1, 'Normal');
```
Insert some data into the table through a procedure to simulate data writing.
```sql
DELIMITER ||
CREATE PROCEDURE batch_insert(IN start_rec INTEGER, IN end_rec INTEGER)
BEGIN
declare a int;
declare b int;
set a=start_rec;
set b=end_rec;
while a<end_rec do
INSERT INTO xxx_metering VALUES(a, '2022-12-28', convert(a, char), '2022-12-28', 1, 'Normal');
set a=a+1;
end while;
end||
DELIMITER ;

CALL batch_insert(1, 10000);
```
Assume that the O&M time is 18:00pm every day, events are set to be triggered at 18:00pm.<br />Create a event for adding a new partition.
```sql
CREATE EVENT IF NOT EXISTS add_partition ON SCHEDULE
EVERY 1 DAY STARTS '2022-12-28 18:00:00'
ON COMPLETION PRESERVE
DO INSERT INTO xxx_metering VALUES(0, DATE_ADD(NOW(), INTERVAL 1 DAY), 0, DATE_ADD(NOW(), INTERVAL 1 DAY), 1, 'Normal');
```
Create a event for dropping a partition.
```sql
DELIMITER ||
CREATE EVENT IF NOT EXISTS drop_partition ON SCHEDULE
EVERY 1 DAY STARTS '2022-12-28 18:00:00'
ON COMPLETION PRESERVE
DO
BEGIN
set @pname = concat('alter table xxx_metering drop partition _p', date_format(curdate(), '%Y%m%d000000'));
prepare stmt_drop_partition from @pname;
execute stmt_drop_partition;
deallocate prepare stmt_drop_partition;
END ||
DELIMITER ;
```
At 2022-12-28 18:00:00, events will be triggered for the first time, drop yesterday's partition (gmt_create between '2022-12-27'~'2022-12-28'), add partition to store tomorrow's data (gmt_create between '2022-12-29'~'2022-12-30'). Every day thereafter, events will be triggered at 18:00:00 to periodically manage partitions.
