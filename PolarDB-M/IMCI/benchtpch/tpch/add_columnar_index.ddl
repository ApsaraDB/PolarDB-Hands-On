alter table  region add columnar index( r_regionkey  ,
                      r_name       ,
                      r_comment   )
                      ;

alter table  nation add columnar index( n_nationkey  ,
                      n_name       ,
                      n_regionkey  ,
                      n_comment    )
                      ;

alter table  part add columnar index( p_partkey     ,
                    p_name        ,
                    p_mfgr        ,
                    p_brand       ,
                    p_type        ,
                    p_size        ,
                    p_container   ,
                    p_retailprice ,
                    p_comment     )
                    ;

alter table  supplier add columnar index( s_suppkey     ,
                        s_name        ,
                        s_address     ,
                        s_nationkey   ,
                        s_phone       ,
                        s_acctbal     ,
                        s_comment     )
                        ;

alter table  partsupp add columnar index( ps_partkey     ,
                        ps_suppkey     ,
                        ps_availqty    ,
                        ps_supplycost  ,
                        ps_comment     )
                        ;

alter table  customer add columnar index( c_custkey     ,
                        c_name        ,
                        c_address     ,
                        c_nationkey   ,
                        c_phone       ,
                        c_acctbal     ,
                        c_mktsegment  ,
                        c_comment     )
                        ;

alter table  orders add columnar index( o_orderkey       ,
                      o_custkey        ,
                      o_orderstatus    ,
                      o_totalprice     ,
                      o_orderdate      ,
                      o_orderpriority  ,
                      o_clerk          ,
                      o_shippriority   ,
                      o_comment        )
                      ;

alter table  lineitem add columnar index( l_orderkey       ,
                        l_partkey        ,
                        l_suppkey        ,
                        l_linenumber     ,
                        l_quantity       ,
                        l_extendedprice  ,
                        l_discount       ,
                        l_tax            ,
                        l_returnflag     ,
                        l_linestatus     ,
                        l_shipdate       ,
                        l_commitdate     ,
                        l_receiptdate    ,
                        l_shipinstruct   ,
                        l_shipmode       ,
                        l_comment        )
                        ;
