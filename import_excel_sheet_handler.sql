/*
1- create temp table for employees
2- import employees excel sheet to temp table 
3- create sequence for employees id, department id, and location id
4- delcrare cursor to loop on employees_temp table and insert rows to employees
5- of employee's job doesn't have job id insert new job id in jobs table with the first three letters of the job name
6- if department name doesn't exist insert it into deprtments and give it new id
7- new deprtments should be connected with their city's location id in locations table 
8- if city doesn't exist, insert it first into cities table  
9- don't accept rows that have not '@' email
*/

--temp table creation
CREATE TABLE Employees_temp (
    Serial number(4) primary key,
    First_name VARCHAR2(100),
    Last_name VARCHAR2(100),
    Hire_date VARCHAR2(100),
    Job_title VARCHAR2(100),
    Salary VARCHAR2(100),
    Email VARCHAR2(100),
    Department_name VARCHAR2(100),
    City VARCHAR2(100)
);

-- sequences creation 
DECLARE
    v_max_emp NUMBER;
    v_max_deprt NUMBER;
    v_max_loc NUMBER;
BEGIN
    -- Get the maximum values for sequences
    SELECT MAX(employee_id) + 1 INTO v_max_emp FROM employees;
    SELECT MAX(department_id) + 1 INTO v_max_deprt FROM departments;
    SELECT MAX(location_id) + 1 INTO v_max_loc FROM locations;

    -- Create sequences
    EXECUTE IMMEDIATE 'CREATE SEQUENCE HR.EMPLOYEES_SEQ START WITH ' || v_max_emp ||
                      ' MAXVALUE 99999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER';

    EXECUTE IMMEDIATE 'CREATE SEQUENCE HR.DEPARTMENTS_SEQ START WITH ' || v_max_deprt ||
                      ' MAXVALUE 99999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER';

    EXECUTE IMMEDIATE 'CREATE SEQUENCE HR.LOCATIONS_SEQ START WITH ' || v_max_loc ||
                      ' MAXVALUE 99999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER';
END;


-- start script   

DECLARE
    -- values that will be prepared for insert 
    v_job_id jobs.job_id%TYPE;
    v_department_id departments.department_id%TYPE;
    v_location_id locations.location_id%TYPE; 
    insert_except exception; -- error when inserting because value is larger than the column require
    pragma exception_init(insert_except, -12899); 
BEGIN
    FOR emp_rec IN (SELECT * FROM employees_temp) LOOP
        -- Check if the job exists in jobs table
        BEGIN
            SELECT job_id INTO v_job_id FROM jobs WHERE job_title = emp_rec.Job_title;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- If job doesn't exist, insert new job into jobs table
                INSERT INTO jobs (job_id, job_title) VALUES (SUBSTR(emp_rec.Job_title, 1, 3), emp_rec.Job_title);
                SELECT job_id INTO v_job_id FROM jobs WHERE job_title = emp_rec.Job_title;
        END;

        -- Check if department exists in departments table
        BEGIN
            SELECT department_id INTO v_department_id FROM departments WHERE department_name = emp_rec.Department_name;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- If the location doesn't exist, insert it into the locations table
                BEGIN
                    SELECT location_id INTO v_location_id FROM locations WHERE city = emp_rec.City;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        INSERT INTO locations (location_id, city) VALUES (locations_seq.NEXTVAL, emp_rec.City);
                        SELECT location_id INTO v_location_id FROM locations WHERE city = emp_rec.City;
                END;

                INSERT INTO departments (department_id, department_name, location_id)
                VALUES (departments_seq.NEXTVAL, emp_rec.Department_name, v_location_id);

                SELECT department_id INTO v_department_id FROM departments WHERE department_name = emp_rec.Department_name;
        END;

        -- Insert row into employees table if email contains '@'
        BEGIN
            IF INSTR(emp_rec.Email, '@') > 0 THEN
                -- Use a CASE statement to handle different date formats
                BEGIN
                    INSERT INTO employees (employee_id, first_name, last_name, hire_date, job_id, salary, email, department_id)
                    VALUES (employees_seq.NEXTVAL, emp_rec.First_name, emp_rec.Last_name,
                            CASE 
                                WHEN INSTR(emp_rec.Hire_date, '-') > 0 THEN TO_DATE(emp_rec.Hire_date, 'DD-MM-YYYY')
                                WHEN INSTR(emp_rec.Hire_date, '/') > 0 THEN TO_DATE(emp_rec.Hire_date, 'DD/MM/YYYY')
                                ELSE NULL -- Handle other date formats or set to NULL
                            END,
                            v_job_id, emp_rec.Salary, emp_rec.Email, v_department_id);
                EXCEPTION
                    WHEN  insert_except THEN
                          DBMS_OUTPUT.PUT_LINE('Value too large for column, ignoring this insert operation.');
                    END;
            END IF;
        END;
    END LOOP;
END;


