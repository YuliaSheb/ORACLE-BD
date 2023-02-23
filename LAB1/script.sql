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

SELECT * FROM myTable;

DROP TABLE myTable;
