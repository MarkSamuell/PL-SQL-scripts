/* 
# First project
__________
dynamic sql : write ddl statements inside plsql code
__________
create seq, trg pairs on all tables in the schema
    - using loop
    - drop all sequences first in the loop 
    - replace any triggers if found =>
    - set sequences to start with max id + 1
        for each table
    ignore increment by [ only increment by 1 ]
    - donot forget to choose the PK column for each table
    - ignore any not numbers primary key or composite keys
*/

-- Enable server output
SET SERVEROUTPUT ON;

DECLARE
    -- Sequences cursor
    CURSOR SEQ_CURSOR IS
        SELECT sequence_name FROM USER_SEQUENCES;

    -- Tables cursor
    CURSOR TAB_CURSOR IS
        SELECT TABLE_NAME,
               LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_id) AS concatenated_columns
        FROM USER_TAB_COLUMNS, USER_OBJECTS
        WHERE USER_TAB_COLUMNS.TABLE_NAME = USER_OBJECTS.OBJECT_NAME
        AND OBJECT_TYPE = 'TABLE'
        GROUP BY TABLE_NAME;

    seq_name VARCHAR2(30); 
    trg_name VARCHAR2(30);
    pk_name VARCHAR2(30);
    pk_max_value NUMBER;
    pk_data_type VARCHAR2(30);

BEGIN
    -- Deleting all sequences in the schema
    FOR seq_RECORD IN SEQ_CURSOR LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq_RECORD.sequence_name;
    END LOOP;

    -- Creating new sequence/trigger pairs for all tables
    FOR tab_record IN TAB_CURSOR LOOP
        -- Resetting the variables for each iteration
        seq_name := tab_record.TABLE_NAME || '_SEQ';
        trg_name := tab_record.TABLE_NAME || '_TRG';

      -- Selecting the primary key columns and their data types 
            SELECT COLUMN_NAME, DATA_TYPE
            INTO pk_name, pk_data_type
            FROM (
                SELECT ACC.COLUMN_NAME, ACC.DATA_TYPE, ACCC.CONSTRAINT_NAME
                FROM USER_TAB_COLUMNS ACC
                JOIN USER_CONS_COLUMNS ACCC ON ACCC.TABLE_NAME = ACC.TABLE_NAME
                    AND ACCC.COLUMN_NAME = ACC.COLUMN_NAME
                WHERE ACC.TABLE_NAME = TAB_RECORD.TABLE_NAME
                    AND ACCC.CONSTRAINT_NAME IN (
                        SELECT CONSTRAINT_NAME
                        FROM USER_CONSTRAINTS
                        WHERE TABLE_NAME = TAB_RECORD.TABLE_NAME
                        AND CONSTRAINT_TYPE = 'P'
                    )
                ORDER BY ACCC.POSITION -- Order by position to maintain the order of columns in the primary key
            ) WHERE ROWNUM = 1; -- Select only the first row, assuming it's a single table with a composite primary key

                    
            -- Check if the data type of the primary key is numeric
            IF pk_data_type = 'NUMBER' THEN
                -- Finding the maximum value of the primary key
                BEGIN
                    DBMS_OUTPUT.PUT_LINE('Dynamic SQL: SELECT TO_NUMBER(MAX(' || pk_name || ')+1) FROM ' || tab_record.TABLE_NAME);
                    EXECUTE IMMEDIATE 'SELECT TO_NUMBER(MAX(' || pk_name || ')+1) FROM ' || tab_record.TABLE_NAME INTO pk_max_value;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error executing dynamic SQL: ' || SQLERRM);
                        pk_max_value := 0; -- Set a default value or handle the error accordingly
                END;
            ELSE
                -- Handle the case where the primary key is not numeric
                DBMS_OUTPUT.PUT_LINE('Primary key (' || pk_name || ') is not of numeric data type. Skipping table ' || tab_record.TABLE_NAME);
                CONTINUE; -- This statement skips to the next iteration of the loop
            END IF;

            -- Creating the sequence if pk_max_value is not null
            IF pk_max_value IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Creating sequence: ' || seq_name);
                EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || seq_name ||
                    ' START WITH ' || TO_CHAR(pk_max_value) ||
                    ' MAXVALUE 99999999 ' ||
                    ' MINVALUE 1 ' ||
                    ' NOCYCLE ' ||
                    ' CACHE 20 ' ||
                    ' NOORDER';
            ELSE
                -- Handle the case where pk_max_value is null
                DBMS_OUTPUT.PUT_LINE('pk_max_value is null. Skipping sequence creation for table ' || tab_record.TABLE_NAME);
                CONTINUE; -- This statement skips to the next iteration of the loop
            END IF;

            -- Creating the trigger
            DBMS_OUTPUT.PUT_LINE('Creating trigger: ' || trg_name);
            EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || trg_name ||
                ' BEFORE INSERT ' ||
                ' ON ' || tab_record.TABLE_NAME ||
                ' REFERENCING NEW AS New OLD AS Old ' ||
                ' FOR EACH ROW ' ||
                ' BEGIN ' ||
                '   :new.' || pk_name || ' := ' || seq_name || '.nextval; ' ||
                ' END;';
    END LOOP;
END;







