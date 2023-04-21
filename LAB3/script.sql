CREATE USER c##dev IDENTIFIED BY pass4dev;
  
CREATE USER c##pod IDENTIFIED BY passpod;

GRANT ALL PRIVILEGES TO c##dev;

GRANT ALL PRIVILEGES TO c##pod;

CREATE TABLE c##dev.animals (
    id  NUMBER NOT NULL,
    name VARCHAR(20),
    group_live NUMBER PRIMARY KEY
    );
    
CREATE TABLE c##dev.forests (
    id  NUMBER NOT NULL,
    name VARCHAR(50),
    CONSTRAINT live FOREIGN KEY (id) REFERENCES c##dev.animals(group_live)
    );
    
CREATE TABLE c##dev.plants (
    id  NUMBER NOT NULL,
    name VARCHAR(50)
    );
    
CREATE TABLE c##pod.animals (
    id  NUMBER NOT NULL,
    name VARCHAR(20),
    group_live NUMBER PRIMARY KEY
    );
    
CREATE TABLE c##pod.zoo (
    id  NUMBER NOT NULL,
    name VARCHAR(50),
    CONSTRAINT live FOREIGN KEY (id) REFERENCES c##pod.animals(group_live)
    );
    
 CREATE OR REPLACE PROCEDURE C##DEV.Proc1 AS
BEGIN
    dbms_output.put_line('It is dev procedure');
END;

CREATE OR REPLACE FUNCTION C##DEV.c_sum ( a NUMBER, b NUMBER) RETURN NUMBER IS
BEGIN
    RETURN a+b;
END;

CREATE OR REPLACE PROCEDURE C##POD.Proc1 AS
BEGIN
    dbms_output.put_line('It is pod procedure');
END;

CREATE OR REPLACE PROCEDURE C##POD.Proc2 AS
BEGIN
    dbms_output.put_line('It is second pod procedure');
END;
    
--Вывод всех таблиц которые есть в схемах, но не одинаковых
select  distinct (table_name) from (
select nvl(dev.table_name, prod.table_name) as table_name,
       nvl(dev.column_name, prod.column_name) as column_name,
       dev.column_name as dev_schema_col,
       prod.column_name as prod_schema_col,
       dev.data_type as dev_schema_type,
       prod.data_type as prod_schema_type
from ( select table_name,
              column_name, data_type
       from sys.all_tab_cols
       where owner = 'C##DEV'      
) dev
full join ( select table_name,
                   column_name, data_type
            from sys.all_tab_cols
            where owner = 'C##POD'  
) prod on prod.table_name = dev.table_name
     and prod.column_name = dev.column_name
     and prod.data_type = dev.data_type
where dev.column_name is null
      or prod.column_name is null
      or dev.data_type <> prod.data_type
);

--Вывод всех таблиц с указанием есть ли они в схеме
select nvl(dev.table_name, prod.table_name) as table_name,
       dev.table_name as dev_schema,
       prod.table_name as prod_schema
from ( select table_name
       from sys.all_tables
       where owner = 'C##DEV'      
) dev
full join ( select table_name
            from sys.all_tables
            where owner = 'C##POD'  
) prod on prod.table_name = dev.table_name;

--Вывод всех таблиц(+столбцов) с указанием есть ли они в схеме
select nvl(dev.table_name, prod.table_name) as table_name,
       nvl(dev.column_name, prod.column_name) as column_name,
       dev.column_name as dev_schema_col,
       prod.column_name as prod_schema_col,
       dev.data_type as dev_schema_type,
       prod.data_type as prod_schema_type
from ( select table_name,
              column_name, data_type
       from sys.all_tab_cols
       where owner = 'C##DEV'      
) dev
full join ( select table_name,
                   column_name, data_type
            from sys.all_tab_cols
            where owner = 'C##POD'  
) prod on prod.table_name = dev.table_name
     and prod.column_name = dev.column_name
     and prod.data_type = dev.data_type
where dev.column_name is null
      or prod.column_name is null
      or dev.data_type <> prod.data_type
order by table_name,
         column_name;
         
CREATE OR REPLACE PROCEDURE different_schemas_tables (
dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AUTHID CURRENT_USER
AS
 TYPE tables_names_arr IS TABLE OF VARCHAR2(100);
 different_t tables_names_arr := tables_names_arr();
 dev_t tables_names_arr;
 prod_t tables_names_arr;
 same_t tables_names_arr;
 not_prod_t tables_names_arr;
 current_table VARCHAR2(100);
 recursion_level INTEGER;
 i INTEGER;
 PROCEDURE add_table(name_t VARCHAR2)
 AS
 parent_tables tables_names_arr := tables_names_arr();
 cycle_error EXCEPTION;
 i INT;
 BEGIN 
 IF (recursion_level > 100) THEN
 dbms_output.put_line('Cycle in ' || name_t);
 RAISE cycle_error;
 END IF;
 IF (name_t MEMBER OF different_t
 OR name_t NOT MEMBER OF not_prod_t) THEN
 RETURN;
 END IF;
SELECT c_pk.table_name
 BULK COLLECT INTO parent_tables
 FROM all_cons_columns a
 JOIN all_constraints c
 ON a.OWNER = c.OWNER
 AND a.constraint_name = c.constraint_name
 JOIN all_constraints c_pk
 ON c.r_owner = c_pk.OWNER
 AND c.r_constraint_name = c_pk.constraint_name 
 WHERE
 c.constraint_type = 'R'
 AND a.table_name = name_t
 AND a.OWNER = dev_schema_name;
 IF (parent_tables.COUNT > 0) THEN 
 i := parent_tables.FIRST;
 WHILE (i IS NOT NULL)
 LOOP 
 recursion_level := recursion_level + 1;
 add_table(parent_tables(i));
 recursion_level := recursion_level - 1;
 i := parent_tables.NEXT(i);
 END LOOP;
 END IF;
 different_t.EXTEND;
 different_t(different_t.COUNT) := name_t;
 dbms_output.put_line('Dev has unique table "'
 || name_t || '"');
 END;
 BEGIN
 SELECT table_name BULK COLLECT INTO dev_t
 FROM all_tables WHERE OWNER=dev_schema_name;
 SELECT table_name BULK COLLECT INTO prod_t
 FROM all_tables WHERE OWNER=prod_schema_name;
 not_prod_t := dev_t MULTISET EXCEPT prod_t;
 i := not_prod_t.FIRST;
 WHILE i IS NOT NULL 
 LOOP
 current_table := not_prod_t(i);
 
 IF (current_table MEMBER OF different_t) THEN
 i := not_prod_t.NEXT(i);
 CONTINUE;
 END IF;
 recursion_level := 0;
 add_table(current_table);
 i := not_prod_t.NEXT(i);
 END LOOP;
 same_t := dev_t MULTISET INTERSECT prod_t;
 i := same_t.FIRST;
 
 WHILE i IS NOT NULL 
 LOOP
 current_table := same_t(i);
 
 IF (dbms_metadata_diff.compare_alter(
 'TABLE', current_table, current_table,
 dev_schema_name, prod_schema_name
 ) = EMPTY_CLOB() ) 
 THEN
 dbms_output.put_line('Dev and Prod has absolutly same "' 
 || current_table || '"');
 ELSIF (dbms_metadata_diff.compare_alter(
 'TABLE', current_table, current_table,
 dev_schema_name, prod_schema_name
 ) IS NOT NULL) 
 THEN
 different_t.EXTEND;
 different_t(different_t.COUNT) := current_table;
 dbms_output.put_line('Dev and Prod has difference in "'
 || current_table || '"'); 
 END IF;
 
 i:= same_t.NEXT(i);
 END LOOP;
 
END;
         
BEGIN
 different_schemas_tables('C##DEV', 'C##POD');
END;  

CREATE OR REPLACE PROCEDURE different_schemas (
 dev_schema_name VARCHAR2,
 prod_schema_name VARCHAR2) AUTHID CURRENT_USER
AS 
 TYPE names_arr IS TABLE OF VARCHAR2(256);
 different names_arr := names_arr();
 recursion_level INTEGER; 
 PROCEDURE add_table(name_t VARCHAR2, table_items names_arr)
 AS
 parent_tables names_arr := names_arr();
 cycle_error EXCEPTION;
 i INT;
 BEGIN
 IF (recursion_level > 100) THEN
 dbms_output.put_line('Cycle in ' || name_t);
 RAISE cycle_error;
 END IF;
 IF (name_t MEMBER OF different
 OR name_t NOT MEMBER OF table_items) THEN
 RETURN;
 END IF;
 SELECT c_pk.table_name
 BULK COLLECT INTO parent_tables
 FROM all_cons_columns a
 JOIN all_constraints c
 ON a.OWNER=c.OWNER
 AND a.constraint_name = c.constraint_name
 JOIN all_constraints c_pk
 ON c.r_owner=c_pk.OWNER
 AND c.r_constraint_name = c_pk.constraint_name
 WHERE
 c.constraint_type = 'R'
 AND a.table_name = name_t
 AND a.OWNER=dev_schema_name;
 IF (parent_tables.COUNT > 0) THEN
 i := parent_tables.FIRST;
 WHILE (i IS NOT NULL)
 LOOP
 recursion_level := recursion_level + 1;
 add_table(parent_tables(i), table_items);
 recursion_level := recursion_level - 1;
 i := parent_tables.NEXT(i);
 END LOOP;
 END IF; 
 
 different.EXTEND;
 different(different.COUNT) := name_t;
 dbms_output.put_line('Dev has unique table "'
 || name_t || '"');
 END; 
 
 PROCEDURE get_items_of_type(item_type VARCHAR2)
 AS
 dev_items names_arr;
 prod_items names_arr;
 not_prod_items names_arr;
 same_items names_arr;
 lines names_arr;
 current_item VARCHAR2(100);
 i INTEGER;
 BEGIN
 CASE item_type
 WHEN 'TABLE' THEN
 SELECT table_name 
 BULK COLLECT INTO dev_items
 FROM all_tables 
 WHERE OWNER=dev_schema_name;
 SELECT table_name
 BULK COLLECT INTO prod_items
 FROM all_tables 
 WHERE OWNER = prod_schema_name;
 WHEN 'PROCEDURE' THEN
 SELECT object_name
 BULK COLLECT INTO dev_items
 FROM all_procedures
 WHERE OWNER=dev_schema_name;
 SELECT object_name
 BULK COLLECT INTO prod_items
 FROM all_procedures
 WHERE OWNER=prod_schema_name; 
 WHEN 'FUNCTION' THEN
 SELECT object_name
 BULK COLLECT INTO dev_items
 FROM all_objects
 WHERE OWNER=dev_schema_name
 AND object_type = 'FUNCTION';
 SELECT object_name
 BULK COLLECT INTO prod_items
 FROM all_objects 
 WHERE OWNER=prod_schema_name
 AND object_type = 'FUNCTION';
 WHEN 'INDEX' THEN
 SELECT index_name
 BULK COLLECT INTO dev_items
 FROM all_indexes 
 WHERE OWNER=dev_schema_name;
 SELECT index_name
 BULK COLLECT INTO prod_items
 FROM all_indexes 
 WHERE OWNER=prod_schema_name; 
 END CASE;
 not_prod_items := dev_items MULTISET EXCEPT prod_items;
 i := not_prod_items.FIRST;
 
 WHILE i IS NOT NULL 
 LOOP
 current_item := not_prod_items(i);
 
 IF (current_item MEMBER OF different) THEN
 i := not_prod_items.NEXT(i);
 CONTINUE;
 END IF;
 IF (item_type = 'TABLE') THEN
 recursion_level := 0;
 add_table(current_item, not_prod_items);
 i := not_prod_items.NEXT(i);
 CONTINUE;
 END IF;
 
 different.EXTEND;
 different(different.COUNT) := current_item;
 
 dbms_output.put_line('Dev has unique '
 || LOWER(item_type)
 || ' "' || current_item || '"');
 END LOOP;
 
 same_items := dev_items MULTISET INTERSECT prod_items;
 i := same_items.FIRST;
 
 WHILE i IS NOT NULL 
 LOOP
 current_item := same_items(i);
 
 IF (item_type IN ('TABLE', 'INDEX')) 
 THEN
 IF (dbms_metadata_diff.compare_alter(
 item_type, current_item,
 current_item, dev_schema_name, 
 prod_schema_name
 ) = EMPTY_CLOB() ) 
 THEN
 dbms_output.put_line(
 'Dev and Prod has absolutly same '
 || LOWER(item_type) || ' "'
 || current_item || '"');
 ELSIF (dbms_metadata_diff.compare_alter(
 item_type, current_item, current_item,
 dev_schema_name, prod_schema_name
 )IS NOT NULL) 
 THEN 
 different.EXTEND;
 different(different.COUNT) := current_item;
 dbms_output.put_line(
 'Dev and Prod has difference in '
 || LOWER(item_type) || ' "'
 || current_item || '"'); 
 END IF;
 
 ELSIF (item_type IN ('PROCEDURE', 'FUNCTION')) THEN
 SELECT nvl(s1.text, s2.text)
 BULK COLLECT INTO lines
 FROM
 (SELECT text FROM all_source
 WHERE type = current_item
 AND OWNER = dev_schema_name) s1
 FULL OUTER JOIN
 (SELECT text FROM all_source
 WHERE type = current_item
 AND OWNER = prod_schema_name) s2 
 ON s1.text = s2.text
 WHERE
 s1.text IS NULL OR s2.text IS NULL;
 
 IF (lines IS NOT NULL) THEN
 different.EXTEND;
 different(different.COUNT) := current_item; 
 dbms_output.put_line(
 'Dev and Prod has difference in '
 || LOWER(item_type) || ' "'
 || current_item || '"');
 END IF;
 END IF;
 
 i:= same_items.NEXT(i);
 
 END LOOP;
 END; 
BEGIN
 get_items_of_type('TABLE');
 dbms_output.put_line('');
 get_items_of_type('FUNCTION');
 dbms_output.put_line('');
 get_items_of_type('PROCEDURE');
 dbms_output.put_line('');
 get_items_of_type('INDEX');
END;

BEGIN
 different_schemas('C##DEV','C##POD');
END;

