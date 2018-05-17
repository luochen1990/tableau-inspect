Tableau Inspect
===============

When using Tableau, sometimes you need to know what Tableau did to your Database, this tool will print out the SQL Queries for you.

Install
-------

First, make sure you have [NodeJS](https://nodejs.org) installed and the command `npm` is available.
Then execute `npm i -g tableau-inspect` to install the CLI command.

Usage
-----

1. Start a console and execute command `tableau-inspect`
2. Use Tableau...
3. View SQL Queries on the console, there may be a delay about 3 or 5 seconds.

Demo
----

```
$ tableau-inspect
C:\Users\Me
## Tableau Repos: ## [
    "My Tableau Repository"
]
## Watching: Logs\log.txt (My Tableau Repository)
## Watching: Logs\tabprotosrv.txt (My Tableau Repository)

-----------------------------------------------------
#I 16:07:32 FROM Logs\log.txt (My Tableau Repository)

Key: qp-batch-summary; Elapsed: 0.05s

SELECT "t0"."store_id" AS "store_id",
  SUM((CASE WHEN ("t0"."__measure__0" > 10) THEN 1 ELSE 0 END)) AS "usr:Calculation_57814962331792"
FROM (
  SELECT "sales_fact_1997"."store_id" AS "store_id",
    "time_by_day"."day_of_month" AS "day_of_month",
    SUM("sales_fact_1997"."store_sales") AS "__measure__0"
  FROM "OLAP_TEST"."sales_fact_1997" "sales_fact_1997"
    INNER JOIN "OLAP_TEST"."time_by_day" "time_by_day" ON ("sales_fact_1997"."time_id" = "time_by_day"."time_id")
  WHERE ("sales_fact_1997"."store_id" IN (2, 3, 6, 7))
  GROUP BY "sales_fact_1997"."store_id",
    "time_by_day"."day_of_month"
) "t0"
GROUP BY "t0"."store_id"

#I 16:07:32 FROM Logs\log.txt (My Tableau Repository)
-----------------------------------------------------
```

Compatibility
-------------

- Tested on Windows 10 and MacOS 10.13
- Tested on Tableau 9.2, Tableau 10.4, Tableau 2018.1

