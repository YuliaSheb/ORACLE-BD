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
    result VARCHAR(10); 
BEGIN
    SELECT count(*) INTO even FROM myTable WHERE mod(val,2)=0;
    SELECT count(*) INTO odd FROM myTable WHERE mod(val,2)!=0;
    IF even>odd THEN RETURN 'TRUE';
    ELSIF even<odd THEN RETURN 'FALSE';
    ELSE RETURN 'EQUAL';
    END IF;
    dbms_output.put_line(odd);
    dbms_output.put_line(even);
    
    RETURN result;
END;

SELECT * FROM myTable;

DROP TABLE myTable;
