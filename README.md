# 1-Auto Increment ID Triggers Handler

## Objective
The objective of this script is to create sequence and trigger pairs on all tables in the schema using dynamic SQL within PL/SQL. The script follows these main steps:

1. Delete all existing sequences in the schema.
2. For each table, drop any existing triggers and create new sequence/trigger pairs.
3. Set sequence values to start with the maximum primary key value + 1 for each table.
4. Handle scenarios where the primary key is not numeric or involves composite keys.

## Execution Steps
1. Enable server output using `SET SERVEROUTPUT ON;`.
2. Use two cursors, `SEQ_CURSOR` for sequences and `TAB_CURSOR` for tables, to iterate over all tables in the schema.
3. Drop existing sequences using dynamic SQL within a loop.
4. For each table, identify the primary key column(s) and their data type(s).
5. Check if the primary key is numeric and proceed to find the maximum value.
6. Create a new sequence starting with the maximum value + 1 if the primary key is numeric.
7. Create a trigger for each table to populate the primary key using the sequence.
8. Output status messages to the server output for each step.

## Considerations
- The script assumes a single schema and iterates over all tables within that schema.
- Composite primary keys are handled by selecting the first column in the composite key for simplicity.
- Non-numeric primary keys or tables with no primary keys are skipped.

## Server Output
The script uses `DBMS_OUTPUT.PUT_LINE` statements to provide informative messages in the server output. Ensure that the server output is enabled to view these messages.

## Error Handling
The script includes basic error handling to handle exceptions during dynamic SQL execution. Error messages are output to the server log.


