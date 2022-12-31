
# Overview

PolarDB for MySQL 8.0 provides the elastic Parallel Query(ePQ) feature. The feature is automatically enabled to reduce the response time of queries when the volume of data you query exceeds a specified threshold.

The elastic parallel query feature supports both single-node elastic parallel query and multi-node elastic parallel query. The latter greatly boosts linear acceleration capabilities and offers multi-node distributed parallel computing. Cost-based optimization makes execution plans flexible and parallel. This solves the issues of the leader performance and unbalanced loads on workers that occur in single-node elastic parallel query. It also overcomes the CPU, memory, and I/O bottlenecks of a single node. Multi-node resource views and adaptive scheduling of parallel computing tasks greatly enhance parallel computing capabilities and reduce query latency, balance the resource loads of nodes, and improve the overall resource usage of the cluster.

![parallel_query-arch](https://user-images.githubusercontent.com/1224612/210052654-b0d6d0e0-e0e8-4aeb-a819-db7e28c1e4c4.png)

# Scenarios
The elastic parallel query feature is applicable to most SELECT statements, such as queries on large tables, multi-table queries that use JOIN statements, and queries on a large amount of data. This feature does not benefit extremely short queries. The diverse parallel methods make the feature suitable for multiple scenarios.

## Analytic queries on vast amounts of data
If medium or large amounts of data is involved, SQL statements for analytic queries are often complex and time-consuming. You can enable the elastic parallel query feature to linearly reduce the response time.

## Imbalanced resource loads
The load balancing ability of PolarProxy can ensure that similar numbers of connections are created for nodes in a cluster. However, due to computing complexity in queries and differences in resource usage, load balancing based connections cannot completely avoid load imbalance between nodes. Like other distributed databases, hotspot nodes have a negative impact on PolarDB:   
* If a hotspot read-only node causes slow queries, the primary node may not purge undo logs and disk bloating may occur.
* If a hotspot read-only node causes slow redo apply operations, the primary node may not flush data and its write throughput is impaired.  

Multi-node elastic parallel query introduces global resource views and adaptive task scheduling based on views. Based on the resource usage and data affinity values of each node, some or all query tasks are scheduled to nodes with idle resources to ensure the degree of parallelism (DOP) and balanced resource usage within the cluster.

![parallel_query-auto](https://user-images.githubusercontent.com/1224612/210052392-a444ebdb-eeb4-4e3b-a1e4-9076312af37c.png)

## Elastic computing
Elasticity is one of the core capabilities of PolarDB. Automatic scaling provides elasticity that is very friendly to short queries. However, it was not applicable to complex analytic queries because a single query still cannot be accelerated by adding nodes in large query scenarios. On clusters with the elastic parallel query feature enabled, newly scaled out nodes are automatically added to the cluster to share computing resources and enhance elasticity.

## Combination of online and offline services
The most effective isolation method is to route the online transaction and offline analytic services to different node sets. According to the characteristics of business scenarios, different clusters can set their own parallel strategies.

![parallel_query-online-offline](https://user-images.githubusercontent.com/1224612/210067397-0873c882-ab0c-4002-87a3-1f9fb5dbaef5.png)

# Quick Start
## Enable the elastic parallel query feature
    
In the Cluster Endpoint section on the Overview page of the console, click Modify. On the Configure Nodes page, set DOP and parallel engine. For more information, see the Parallel Query parameter in Configure [PolarProxy](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/configure-polarproxy#task-1580301).

We recommend that you use the following parallel query settings:
* Increase the value of the max_parallel_degree parameter in small increments. We recommend that the value should not exceed a quarter of the total number of CPU cores. For example, after you set the max_parallel_degree parameter to 2, you can check the CPU utilization on the next day. If the CPU utilization is low, increase the value of the max_parallel_degree parameter. If the CPU utilization is high, do not increase the value.
* DOP specifies the maximum number of worker threads that can run simultaneously in a single compute node for a single query. If you select multi-node elastic parallel query, the maximum number of worker threads that can run simultaneously in a single query is the product of degree of parallelism and the number of nodes.
* When you enable the elastic parallel query feature, set the innodb_adaptive_hash_index parameter to OFF. If the innodb_adaptive_hash_index parameter is set to ON, the performance of parallel query is degraded.


## Use Hints
You can optimize an individual SQL statement by using hints. For example, if the elastic parallel query feature is disabled by the system, you can use hints to accelerate a slow SQL query that is frequently executed. For more information, see [Parallel hints](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/parallel-hints?spm=a2c63.p38356.0.0.77b55b25hDpXfu#concept-2567761).

# View elastic parallel query execution plans
For more information about how to execute the EXPLAIN statement to view elastic parallel query information in execution plans, see View elastic [parallel query execution plans](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/view-parallel-execution-plans?spm=a2c63.p38356.0.0.77b55b25hDpXfu#concept-2059476).

# Performance metrics
The following tests use 100 GB of data that is generated based on TPC Benchmark H (TPC-H) to test the performance of a PolarDB for MySQL 8.0 cluster. 
> In the test, the PolarDB cluster has four nodes that use 32-core CPUs and 256-GB memory (Dedicated). For single-node elastic parallel query, the max_parallel_degree parameter is set to 32 and 0. Compare the performance data for sequential query, and multi-node elastic parallel query with DOP of 128 and four nodes.

![20221230163224](https://user-images.githubusercontent.com/1224612/210050532-a1ab0fbf-108b-4a1b-83ab-4e92e0c7e48d.jpg)

When multi-nodes elastic parallel query is enabled, the query speed is `59 times` faster on average and `159 times` faster at maximum.

For more information, see [Performance test results in parallel query scenarios](https://www.alibabacloud.com/help/en/polardb-for-mysql/latest/parallel-query-performance-in-olap-scenarios?spm=a2c63.p38356.0.0.3ecf556e6LXwnL#task-2350322).


# Variables Description
| Variables | Level | Description  |
|-----------|-------|--------------|
|max_parallel_degree | Global and session | The maximum DOP for an individual query. This parameter specifies the maximum number of workers that are used to run queries in parallel. 
|parallel_degree_policy| Global | Specify a DOP policy for an individual query. Valid values: <br> * `TYPICAL` : PolarDB sets the DOP to the same value as max_parallel_degree, regardless of database loads, such as CPU utilization. <br> * `AUTO` : PolarDB enables or disables the elastic parallel query feature based on database loads, such as CPU utilization, and selects the DOP based on the costs of queries. <br> * `REPLICA_AUTO (default)` : Only read-only nodes determines whether to enable the elastic parallel query feature based on database loads, such as CPU utilization, and select the DOP based on the costs of queries. The primary node does not perform elastic parallel query. |
| parallel_workers_policy | session | The elastic parallel query policy. Valid values: <br> * `LOCAL` :single-node elastic parallel query. <br> * `AUTO` : The elastic parallel query feature is enabled. Task scheduling is based on the real-time loads of the nodes in the cluster. If the computing resources of a node are insufficient, idle resources of other nodes in the cluster can be tried. Multi-node elastic parallel query is enabled when the query cost exceeds the specified threshold. <br> * `MULTI_NODE` : Forces multi-node elastic parallel query. The maximum DOP increases with the number of nodes. This value is suitable for analytic queries on vast amounts of data.
records_threshold_for_parallelism | Session | If the number of scanned rows exceeds the value of records_threshold_for_parallelism, the optimizer enables the elastic parallel query feature.
cost_threshold_for_parallelism | Session | If the cost of sequential queries exceeds the value of the cost_threshold_for_parallelism parameter, the optimizer enables the elastic parallel query feature.
records_threshold_for_mpp | Session | If the number of scanned rows of a table involved in a query statement exceeds this threshold, the optimizer considers using multi-node elastic parallel query.
cost_threshold_for_mpp | Session | If the sequential execution cost of a query statement exceeds this threshold, the optimizer considers using multi-node elastic parallel query.
