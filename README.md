# Revenue calculation under IFRS 15
## **Subject Description**
A set of interrelated stored procedures calculating revenue according to IFRS* 15 “Revenue from Contracts with Customers”. Per standard, short-term contract are those with duration of two years or less (hereinafter STP), whereas multiyear contracts are contracts durating more than two years.
Standard requires that revenue is calculated differently on short term contracts and multiyear contracts. For receivables from customer are recognized in full against revenue. On multiyear contracts receivals are recognized against two accounts:

1)	Revenue (contract value for two first years of the contract),
2)	Deferred revenue (contract value for the remainder contract term) 
For instance, contract duration is 5 years and total value is 120 money units including VAT of 20%**, on contract inception date following accounting entries are made

| Account	                         | Amount (money units) |
|----------------------------------|----------------------|
|Dr Receivables	                   |                  100 |
|        Cr Revenue                |                   40 |
|        Cr Deferred Revenue       |                   60 |                                      


Starting next month after contract inception amount booked to deferred revenue are amortized to revenue account over period calculated as total contract duration less two years. Thus 100% of contract value is recognized as revenue during period of duration contract less 23 months. 
Amortized revenue recognized through entry

| Account	                         | Amount (money units) |
|----------------------------------|----------------------|
|Dr Deferred Revenue	             |                 1,69 |
|        Cr Revenue                |                 1,69 |

## **Project’s structure**
Main procedure is FORM_PERIOD_REVENUE which simply saves calculated revenue amounts to DataMart (special table in DB). Revenue is calculated by two procedure QUERY_STP for short-term contracts and QUERY_MYP for multiyear contracts. The later uses three auxiliary procedures LT_REWARD_P, LT_REWARD_SA, LT_REWARD_CN for different types of contracts. Procedures STR_LOB and STR_LOB_RE are also auxiliary ones and simply convert several values selected from a table into a string.
__________________________________________________________________________________________
*IFRS – *International Financial Reporting Standard*

**VAT – *Value Added Tax, i.e. indirect tax paid by final consumer of a good or service. Seller only collects this amount from customer with obligation of consequent transfer of collected tax to state authorities. This is why 20% are excluded.*
