# ===================================================================== #
# Database and variator
# ===================================================================== #

This scripts can't use database. It's because sometimes values rely on many
variables.

For example to get max latency for opeator we need to know his fraction.
Based on that we have ranges of latency.
Fraction however depends on other values.
Therefor we have an ladder of dependencies. 
It's not good to encode that in database.

It's possible to store in DB only values (data) and store logic in script.
This is right now too much.

