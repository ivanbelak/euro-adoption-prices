# Did the euro make Croatia more expensive?

🇬🇧 English | [🇭🇷 Hrvatski](README.hr.md)

I made this project mainly as practice in Power BI, SQL and Python. I picked the topic as a test of my own
naivety - I believed prices would not rise significantly just because of the euro.

I wanted to separate the effect of the euro from general inflation. I compared Croatia's price growth with
the euro area (EA19), but also with similar countries that haven't switched to the euro. As an extra, I ran the
same comparison for the five other countries that have adopted the euro since 2007.

As for goods, maybe I wasn't that naive after all - there appears to be no significant effect. For services, though,
it's a different story - across all six countries, they rose about 1.5 points more than in the comparison
countries in the first year of the euro.
For Croatia alone the effect goes the same way, but it is hard to say exactly how big it is, because the euro
came in the middle of the 2022 inflation wave.

With services, the effect is clearest where people pay small amounts often: restaurants and cafés, canteens,
hairdressers, recreation and sport, and household appliance repairs. These rose more than in the comparison
countries in almost all six countries, by 2 to 3 points on average. For telecoms (mobile, internet), where
prices are set by large companies, there is no effect.

Along the way I had to correct my conclusion a few times: the first result looked clearer than it really
was, until I added a second comparison group and a test with "fake" adoption dates.

I wrote the code with help from [Claude Code](https://claude.com/claude-code). I chose the topic, the data,
the time window, which countries to compare with, and how the report should look in Power BI.

Bulgaria adopted the euro in 2026, so in early 2027 I will check whether the same holds there.

![Power BI report: prices in Croatia and the euro area around euro adoption](docs/img/croatia_vs_control.png)

## Try the report

Download `EuroPrices.pbix` (data included) from the
[latest release](https://github.com/ivanbelak/euro-adoption-prices/releases/latest) and open it in the free
[Power BI Desktop](https://www.microsoft.com/power-platform/products/power-bi/desktop) (Windows). Pick a
country, a comparison group, a category and a time window, and the charts follow.

## More detail

Method, all result tables, the placebo test, data quality notes and how to rebuild everything:
**[docs/METHODOLOGY.md](docs/METHODOLOGY.md)**.

What's in the repository:

- `src/` - Python: downloads Eurostat and FRED data, loads it into SQL Server, placebo test logic
- `sql/` - SQL Server: star schema, event study and pre-trend views
- `powerbi/` - the Power BI report (PBIP project format)
- `notebooks/` - the placebo test, with charts
