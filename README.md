# Northwind Business Status Dashboard

**SQL Data Analytics Bootcamp — Week 4**

A Redash-based monitoring dashboard built on the Northwind database, focused on
**current-state visibility** rather than hypothesis testing (see Week 3 for the
hypothesis-driven analysis report).

## Reference Point

- **Data as of**: 2021-09-19 (last available order date in the dataset)
- **Reporting window**: trailing 12 months (2020-10 ~ 2021-09)
- Note: 2021-09 is a partial month (data through the 19th only). This is called out
  explicitly wherever it could distort interpretation (e.g., excluded from the
  month-over-month growth calculation).

## Dashboard Structure

| Section | Chart | Description |
|---|---|---|
| Sales | Monthly Revenue Trend | Line chart, last 12 months |
| Sales | MoM Revenue Growth (%) | Diverging bar chart, complete months only |
| Orders & Shipping | Monthly Order Volume | Line chart, last 12 months |
| Orders & Shipping | Shipping Status Breakdown | On-time vs. delayed, donut chart |
| Category Mix | Category Revenue Share | Pie chart, 8 categories |
| Inventory | Products Below Reorder Level | Table, active products only |
| Customers | Revenue by Country | Bar chart, sorted descending |
| Customers | Active vs. Dormant Customers | Donut chart, based on last order date |

## Key Findings

- Delayed shipments: **~23.4%** of all orders in the trailing 12 months
- Active customer ratio: **95.8%** (customers with an order in the last 12 months)
- Revenue growth is volatile month-to-month but shows no sustained decline trend

## Tools

MySQL (Redash) — date functions, self-joins for period-over-period comparison,
CASE WHEN-based bucketing, diverging bar chart pattern (split positive/negative
series for color-coded rendering)

## Notes on Query Design

- `MoMGrowthPct` requires a **self-join** to compare each month against the
  previous one, since this MySQL version does not support window functions
  (`OVER()`).
- The last (partial) month is excluded from the growth-rate calculation only,
  since comparing a 19-day month against a full 31-day month would distort the
  percentage. It is still included in the trend line charts, since the dashboard's
  purpose is to reflect the most current state.

See [`queries.sql`](./queries.sql) for the full set of queries.


