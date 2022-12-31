
# Elastic Parallel Query
## Overview
PolarDB for MySQL 8.0 provides the elastic Parallel Query(ePQ) feature. The feature is automatically enabled to reduce the response time of queries when the volume of data you query exceeds a specified threshold.

The principle of parallel query is to split a large query task into multiple sub-query tasks, and distribute the sub-tasks to multiple threads for concurrent processing. The core idea is to use the concurrent processing capability of multi-core chips to speed up the query. Elastic parallel query also supports distributing subtasks to multiple nodes for execution, have better elastic expansion ability.

![parallel_query-arch](https://user-images.githubusercontent.com/1224612/210052654-b0d6d0e0-e0e8-4aeb-a819-db7e28c1e4c4.png)


## Business Scenario
The elastic parallel query feature is applicable to most SELECT statements, such as queries on large tables, multi-table queries that use JOIN statements, and queries on a large amount of data. This feature does not benefit extremely short queries. The diverse parallel methods make the feature suitable for multiple scenarios.

### Analytic queries on vast amounts of data
If medium or large amounts of data is involved, SQL statements for analytic queries are often complex and time-consuming. You can enable the elastic parallel query feature to linearly reduce the response time.

The steps is based on that we have an PolarDB MySQL instance, and we connected a session to the instance.
The following PolarDB cluster and test data is used in the example:    
* The node specification is 8 Cores and 64GB Memory.
* [Generate test data by TPC-H tools](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/olap-performance-tests#section-eu0-9uo-dit), the scale factor of data is 100 (100GB).


#### Step 1: Set Cluster Endpoints as Read-Only Mode.
Click modify.
![image](https://user-images.githubusercontent.com/1224612/210136613-b7e55a1c-4743-4226-8bea-cd2fb70b3f33.png)
Set Cluster Endpoints as Read-Only Mode.
![image](https://user-images.githubusercontent.com/1224612/210136676-21f5b0ce-31f0-4e56-852c-20854e4defaa.png)

#### Step 2: Connected a session to the Cluster Endpoints, and warm up the data.

```SQL
-- warm up the data.
mysql> select count(*) from part;
+----------+
| count(*) |
+----------+
| 20000000 |
+----------+
```

#### Step 3: Test an aggregation analysis query without ePQ.

```SQL
mysql> select avg(P_RETAILPRICE),min(P_RETAILPRICE),max(P_RETAILPRICE) from part;
+--------------------+--------------------+--------------------+
| avg(P_RETAILPRICE) | min(P_RETAILPRICE) | max(P_RETAILPRICE) |
+--------------------+--------------------+--------------------+
|        1499.495035 |             900.01 |            2098.99 |
+--------------------+--------------------+--------------------+
1 row in set (8.55 sec)
-- View the query plan.
```

Without ePQ, the query time is `8.55` sec.

#### Step 4: Turn on ePQ.
Click the On option of Parallel Query.
![image](https://user-images.githubusercontent.com/1224612/210137461-eab90191-c114-469b-81f9-368eb57da494.png)

Configure degree of parallel is 8, and click OK.
![image](https://user-images.githubusercontent.com/1224612/210137510-16cb716d-c9c2-4c34-8019-c83ff6f1f91b.png)


#### Step 5: Test the same query with ePQ is enabled.

> Note: The modified configuration is only valid for new session connections, so you need to disconnect and reconnect the session before testing.

```SQL
mysql> select avg(P_RETAILPRICE),min(P_RETAILPRICE),max(P_RETAILPRICE) from part;
+--------------------+--------------------+--------------------+
| avg(P_RETAILPRICE) | min(P_RETAILPRICE) | max(P_RETAILPRICE) |
+--------------------+--------------------+--------------------+
|        1499.495035 |             900.01 |            2098.99 |
+--------------------+--------------------+--------------------+
1 row in set (1.57 sec)
```

After enabled ePQ， the query time is speedup to `1.57` sec. By checking the query plan, the elastic parallel query uses 8 parallel workers(threads) to speed up the query.

Query Plan:
![image](https://user-images.githubusercontent.com/1224612/210137925-37ba9f4d-6ff2-4f18-b7d9-95f26de1076e.png)

#### Step 6: Add a Read-only Node to Cluster.
Click Add/Remove Node, and add a Read-only node which has same specification.
![image](https://user-images.githubusercontent.com/1224612/210138036-f6a1834e-1b88-491c-b14e-900bbeed48bf.png)

You need to wait for the new node to be added successfully.
![image](https://user-images.githubusercontent.com/1224612/210138228-37216e08-10ba-4b72-a12b-2650b17daea2.png)


#### Step 7: Test the same query after new read-only node is added.

```SQL
mysql> select avg(P_RETAILPRICE),min(P_RETAILPRICE),max(P_RETAILPRICE) from part;
+--------------------+--------------------+--------------------+
| avg(P_RETAILPRICE) | min(P_RETAILPRICE) | max(P_RETAILPRICE) |
+--------------------+--------------------+--------------------+
|        1499.495035 |             900.01 |            2098.99 |
+--------------------+--------------------+--------------------+
1 row in set (0.62 sec)
```

After a new node is expanded to the cluster, the query response time is speedup to `0.62` sec. By checking the query plan, the number of parallel workers is flexibly adjusted to 16, that because the cluster has two idle computing nodes currently.

![image](https://user-images.githubusercontent.com/1224612/210138619-ad76a582-bfad-4b34-afb1-41b4bcd278c8.png)

#### Step 8: Comparison of test results 
| | ePQ=OFF  | ePQ=ON | ePQ=ON
|--|-----------| -----| --------|
|The number of nodes | 1 | 1 | 2
|The query response time | 8.55 sec| 1.57 sec | 0.62 sec

Enabled elastic parallel query , the response time of the slow query can be reduced linearly.


### Resource Management
The core idea of parallel query is to use the idle computing resources of nodes in the cluster to speed up the query in parallel, which is very suitable for the scenario where the utilization rate of cluster resources is not high. When the cluster load is already high, it will automatically limit the parallelism of parallel queries to prevent resource overload.