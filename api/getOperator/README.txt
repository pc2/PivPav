getOperator

It read necessary data from the database and creates flopoco VHDL operator.
This is equivalent with creating circuit under flopoco.
The entity of the circuit is fetched from the DB and created operator (under
Flopoco) has corresponding structure.
This allows to connect several operators together.


Fetching from DB is done with the sqlite-c tool.
This tool needs to know about the DB structure.
