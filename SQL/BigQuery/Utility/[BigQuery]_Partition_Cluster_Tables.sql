-- Resource -
-- https://cloud.google.com/bigquery/quotas#partitioned_tables

-- Partitioning- Dividing data
-- Clustering- gathering data

-- When we should not partition data?
-- Partition results in a small amount of data per partition(less than 1GB)
-- Partitioning results in a large number of partitions(max 4000 partitions allowed per table)
-- Partitioning results in mutation operations modifying the majority of partitions in the table frequently.
-- There is no limit on the number of clusters in a table, So consider using it in case partitioned tables reach quota limits.
