# Je li uvođenje eura podiglo cijene u Hrvatskoj?

[🇬🇧 English](README.md) | 🇭🇷 Hrvatski

Projekt sam napravio prvenstveno kao vježbu u Power BI-ju, SQL-u i Pythonu. Temu sam izabrao kao test
svoje naivnosti - vjerovao sam da cijene neće rasti značajno isključivo zbog uvođenja eura.

Zanimalo me koliko je rast cijena u Hrvatskoj bio posljedica uvođenja eura, a koliko rezultat općenite
inflacije. Zato sam ga usporedio s rastom cijena u eurozoni, ali i u sličnim zemljama koje nisu uvele euro.
Kao dodatni zadatak, isto sam napravio i za 5 ostalih država koje su uvele euro od 2007.

Što se tiče dobara, možda i nisam bio tako naivan - ne vidi se značajan efekt. Međutim, kod usluga je priča
drugačija - gledajući svih šest zemalja, u prvoj godini eura poskupjele su oko 1,5 bod više od usporednih
zemalja. Za samu Hrvatsku efekt je
istog smjera, ali je teško reći koliko je točno velik, jer je euro uveden usred inflacijskog vala 2022.

U izvještaju se rast cijena rastavlja na tri dijela: koliko su cijene porasle u usporednim zemljama u
isto vrijeme (opća inflacija), koliko je Hrvatska ionako rasla brže i prije eura, te ono što ostaje -
procjena efekta eura.

Kod usluga se efekt najjasnije vidi tamo gdje se plaća sitno i često: restorani i kafići, menze, frizeri,
rekreacija i sport te popravci kućanskih aparata. Te usluge poskupjele su više nego u usporednim zemljama u
gotovo svih šest zemalja, u prosjeku za 2 do 3 boda. Kod telekomunikacija (mobitel, internet), gdje cijene
određuju velike tvrtke, efekta nema.

Usput sam nekoliko puta morao korigirati zaključak: prvi rezultat je izgledao jasnije nego što jest, sve dok
nisam dodao drugu usporednu skupinu i provjeru s "lažnim" datumima uvođenja eura.

Kod sam pisao uz pomoć [Claude Codea](https://claude.com/claude-code). Ja sam birao temu, podatke, raspon i s
kojim zemljama uspoređivati, te kako izvještaj treba izgledati u Power BI-ju.

Bugarska je uvela euro 2026., pa ću početkom 2027. provjeriti vrijedi li isto i za nju.

![Power BI izvještaj: cijene u Hrvatskoj i europodručju oko uvođenja eura](docs/img/croatia_vs_control.png)

## Isprobaj izvještaj

Preuzmi `EuroPrices.pbix` (s podacima) iz
[zadnjeg izdanja](https://github.com/ivanbelak/euro-adoption-prices/releases/latest) i otvori ga u besplatnom
[Power BI Desktopu](https://www.microsoft.com/power-platform/products/power-bi/desktop) (Windows). Odabereš
zemlju, usporednu skupinu, kategoriju i vremenski prozor, a grafovi se prilagode. Izvještaj je na engleskom.

## Više detalja

Metoda, sve tablice s rezultatima, placebo test, napomene o kvaliteti podataka i kako sve ponovo izgraditi:
**[docs/METODOLOGIJA.md](docs/METODOLOGIJA.md)**.

Što je u repozitoriju:

- `src/` - Python: preuzimanje podataka s Eurostata i FRED-a, punjenje SQL Servera, logika placebo testa
- `sql/` - SQL Server: zvjezdasta shema, viewovi za event study i prethodne trendove
- `powerbi/` - Power BI izvještaj (format PBIP projekta)
- `notebooks/` - placebo test, s grafovima
