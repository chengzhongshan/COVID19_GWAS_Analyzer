/*
This macro program first generates the orders and quotes data sets, then joins them
using both the SAS PROC SQL and the SyncJoin algorithm, and finally compares the
results from the two approaches. By systematically changing the parameter values and
invoking the macro repeatedly, the performance differences between the SyncJoin method
and the SAS PROC SQL, in terms of total CPU time required, are clearly demonstrated.
Here are the macro parameters:
days = <number of days; used to control the number of observations generated>
multipleorder = <yes to allow multiple same-time orders; no for single order>
multiplequote = <yes to allow multiple same-time quotes; no for single quote>
quoteduration = <maximum number of seconds that a quote can last, from 1 to 5>
variableduration = <yes to allow quote duration to vary from 1 to 5; no to fix to 5>
*/
%macro sql_vs_syncjoin (days=10, multipleorder=yes, multiplequote=yes,
quoteduration=5, variableduration=yes);
options fullstimer;
/* Generate an orders dataset for the stock ABCD */
data orders (keep=order_id stock_name order_time customer_id order_side order_price
order_quantity filler_order);
format order_id 8. stock_name $8. order_time datetime20. customer_id order_side $8.
order_price 8.2 order_quantity 8. filler_order $456.;
stock_name = "ABCD";
filler_order = "<Put random characters in the string to make it long or short>";
begin = today() * 86400 + "8:00:00"t;
end = (today() + &days - 1) * 86400 + "18:00:00"t;
do time = begin to end;
random = ranuni(0);
%if %upcase(&multipleorder) = YES %then
order_count = int(10 * random) + 1;
%else
order_count = 1;;
do counter = 1 to order_count;
random = ranuni(0);
if random < 0.5 then do;
order_id + 1;
order_time = time;
customer_id = "cs_" || compress(int(random * 10000));
if random < 0.25 then do;
order_side = "BUY";
order_price = 10 + mod(round(random, 0.1), 0.2);
end;
else do;
order_side = "SELL";
order_price = 10 - mod(round(random, 0.1), 0.3);
end;
order_quantity = round(1000 * mod(random, 0.3), 100) + 100;
output;
end;
end;
if timepart(time) = "18:00:00"t then
time + 50399;
end;
run;
/* Generate a quotes dataset for the stock ABCD */
data quotes (keep=quote_id stock_name quote_time quote_end_time broker_id buy_price
buy_quantity sell_price sell_quantity filler_quote);
format quote_id 8. stock_name $8. quote_time quote_end_time datetime20.
broker_id $8. buy_price 8.2 buy_quantity 8. sell_price 8.2 sell_quantity 8.
filler_quote $440.;
stock_name = "ABCD";
filler_quote = "<Put random characters in the string to make it long or short>";
begin = today() * 86400 + "8:00:00"t;
end = (today() + &days - 1) * 86400 + "18:00:00"t;
do time = begin to end;
random = ranuni(0);
%if %upcase(&multiplequote) = YES %then
quote_count = int(10 * random) + 1;
%else
quote_count = 1;;
do counter = 1 to quote_count;
random = ranuni(0);
if random < 0.5 then do;
quote_id + 1;
quote_time = time;
%if %upcase(&variableduration) = YES %then
quote_end_time = quote_time + mod(int(random * 10), &quoteduration);
%else
quote_end_time = quote_time + 4;;
broker_id = "bk_" || compress(int(random * 10000));
buy_price = 10 - mod(round(random, 0.1), 0.2);
sell_price = 10 + mod(round(random, 0.1), 0.3);
if buy_price = sell_price then
sell_price + 0.2;
if random < 0.125 then do;
buy_quantity = 300;
sell_quantity = 100;
end;
else if random > 0.375 then do;
buy_quantity = 100;
sell_quantity = 300;
end;
else do;
buy_quantity = 200;
sell_quantity = 200;
end;
output;
end;
end;
if timepart(time) = "18:00:00"t then
time + 50399;
end;
run;
/* Link orders to effective quotes – Rely on Proc SQL query optimizations */
proc sql noprint _method;
create table matches_sql as
select *
from orders a,
quotes (rename=(stock_name=quote_stock_name)) b
where a.order_time between b.quote_time and b.quote_end_time
and (a.order_side = "BUY" and
b.sell_quantity = a.order_quantity and
b.sell_price = a.order_price
or
a.order_side = "SELL" and
b.buy_quantity = a.order_quantity and
b.buy_price = a.order_price);
quit;
/* Link orders to effective quotes – Use the SyncJoin algorithm */
/* Sort the orders and quotes properly */
proc sort data=orders;
by order_time;
run;
proc sort data=quotes;
by quote_time quote_end_time;
run;
/* Match orders with effective quotes */
data matches_syncjoin (drop=continue firstmatchobs);
retain nextobs 1 firstmatchobs;
set orders;
by order_time;
if first.order_time then
firstmatchobs = 0;
continue = 1;
do while	(continue);
set quotes (rename=(stock_name=quote_stock_name)) nobs=quotescount
point=nextobs;
if quote_end_time < order_time then do;
if nextobs < quotescount then
nextobs + 1;
else
continue = 0;
end;
else if quote_time > order_time then do;
continue = 0;
if firstmatchobs > 0 then
nextobs = firstmatchobs;
end;
else do;
if firstmatchobs = 0 then
firstmatchobs = nextobs;
if order_side = "BUY" and
sell_quantity = order_quantity and
sell_price = order_price
or
order_side = "SELL" and
buy_quantity = order_quantity and
buy_price = order_price then
output;
if nextobs < quotescount then
nextobs + 1;
else do;
continue = 0;
if firstmatchobs > 0 then
nextobs = firstmatchobs;
end;
end;
end;
run;
/* Sort the results and compare them */
proc sort data=matches_sql;
by order_id quote_id;
run;
proc sort data=matches_syncjoin;
by order_id quote_id;
run;
proc compare data=matches_sql compare=matches_syncjoin;
run;
%mend;
/* Run the macro repeatedly and collect the statistics */
/*Demo codes:;

%sql_vs_syncjoin (days=1);

*/

