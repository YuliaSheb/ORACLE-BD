CREATE TABLE myTable
(
 id number PRIMARY KEY,
 val number NOT NULL 
);

DECLARE
    peremen number := 0;
BEGIN 
   WHILE peremen <= 10000
   LOOP
    peremen := peremen + 1;
    INSERT INTO myTable VALUES (peremen, ROUND(dbms_random.value(1,10000)));
   END LOOP;
END;

CREATE OR REPLACE FUNCTION even_odd  RETURN VARCHAR IS 
    even number(10);
    odd number(10); 
BEGIN
    SELECT count(*) INTO even FROM myTable WHERE mod(val,2)=0;
    SELECT count(*) INTO odd FROM myTable WHERE mod(val,2)!=0;
    IF even>odd THEN RETURN 'TRUE';
    ELSIF even<odd THEN RETURN 'FALSE';
    ELSE RETURN 'EQUAL';
    END IF;
END;

CREATE OR REPLACE FUNCTION generate_text_id (input_id IN number) RETURN VARCHAR IS
    val_id number;
BEGIN
    SELECT val INTO val_id FROM myTable WHERE id = input_id;
    RETURN 'INSERT INTO myTable(id,val) VALUES ('||input_id||','||val_id||');';
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 'Data not found'; 
END;

BEGIN
    dbms_output.put_line(even_odd());
END;

BEGIN
    dbms_output.put_line(generate_text_id(34));
END;

SELECT generate_text_id(3) from DUAL;

SELECT even_odd() from DUAL;

CREATE OR REPLACE PROCEDURE insert_procedure (inp_id IN number, inp_val IN number) IS
BEGIN
   INSERT INTO MyTable(id, val) VALUES (inp_id, inp_val);
end;

CREATE OR REPLACE PROCEDURE delete_procedure (inp_id IN number) IS
BEGIN
   DELETE FROM MyTable WHERE id=inp_id;
end;

CREATE OR REPLACE PROCEDURE update_procedure (inp_id IN number, inp_val IN number) IS
BEGIN
   UPDATE MyTable SET val=inp_val WHERE id=inp_id;
end;

begin
 insert_procedure(10004, 1);
end;

begin
 delete_procedure(10004);
end;

begin
 update_procedure(10003,22);
end;

CREATE OR REPLACE FUNCTION salary(month_earn REAL, proceent number) RETURN VARCHAR IS
earn REAL;
BEGIN
    IF month_earn<0 OR proceent<0 OR proceent>100 THEN RETURN 'error';
    END IF;
    earn := (1+(proceent/100))*12*month_earn;
    RETURN ''||earn||'';
END;

SELECT salary(100, 10) from DUAL;

SELECT * FROM myTable;

DROP TABLE myTable;
