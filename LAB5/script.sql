CREATE TABLE zooo(
    id NUMBER PRIMARY KEY,
    name VARCHAR2(15),
    city VARCHAR2(15),
    country VARCHAR2(15)
);

CREATE TABLE zoo_habitans(
    id NUMBER PRIMARY KEY,
    zoo_id NUMBER,
    type VARCHAR2(15),
    CONSTRAINT fk_zoo_habitans FOREIGN KEY (zoo_id) REFERENCES zooo(id)
    );

CREATE TABLE type_habitans(
    id NUMBER PRIMARY KEY,
    name VARCHAR2(15),
    birthd date,
    type_id NUMBER,
    count_habitans NUMBER,
    CONSTRAINT fk_zoo_type FOREIGN KEY (type_id) REFERENCES zoo_habitans(id)
    );

DROP TABLE type_habitans;
    
CREATE TABLE log_zoo(
    operation_id NUMBER PRIMARY KEY,
    operation VARCHAR2(15),
    times TIMESTAMP NOT NULL,
    id NUMBER,
    name VARCHAR2(15),
    city VARCHAR2(15),
    country VARCHAR2(15)
    );
    
CREATE TABLE log_habitans(
    operation_id NUMBER PRIMARY KEY,
    operation VARCHAR2(15),
    times TIMESTAMP NOT NULL,
    id NUMBER,
    type VARCHAR2(15),
    zoo_id NUMBER
    );
    
CREATE TABLE log_type(
    operation_id NUMBER PRIMARY KEY,
    operation VARCHAR2(15),
    times TIMESTAMP NOT NULL,
    id NUMBER,
    name VARCHAR2(15),
    birthd date,
    type_id NUMBER,
    count_habitans NUMBER
    );
    
CREATE TABLE logs(
    operation_id NUMBER PRIMARY KEY,
    id NUMBER,
    operation VARCHAR2(15),
    times TIMESTAMP NOT NULL,
    table_name VARCHAR2(15)
    );
    
DROP TABLE log_type;
    
CREATE OR REPLACE TRIGGER log_zoo 
AFTER UPDATE OR INSERT OR DELETE ON zooo FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    curr_time TIMESTAMP;
    table_name VARCHAR2(15) := 'log_zoo';
    count_op NUMBER := 0;
    count_op_all NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM log_zoo' INTO count_op;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM logs' INTO count_op_all;
    curr_time := CURRENT_TIMESTAMP;
    CASE
        WHEN inserting THEN 
            INSERT INTO log_zoo VALUES (count_op+1,'INSERT',curr_time, :NEW.id, :NEW.name, :NEW.city, :NEW.country);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'INSERT',curr_time,table_name);
        WHEN updating THEN 
            INSERT INTO log_zoo VALUES (count_op+1,'UPDATE',curr_time, :OLD.id, :OLD.name, :OLD.city, :OLD.country);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'UPDATE',curr_time, table_name);
        WHEN deleting THEN 
            INSERT INTO log_zoo VALUES (count_op+1,'DELETE',curr_time, :OLD.id, :OLD.name, :OLD.city, :OLD.country);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'DELETE',curr_time, table_name);
    END CASE;
    commit;
END;

DROP TRIGGER log_habitans;

CREATE OR REPLACE TRIGGER log_habitans 
AFTER UPDATE OR INSERT OR DELETE ON zoo_habitans FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    curr_time TIMESTAMP;
    table_name VARCHAR2(15) := 'log_habitans';
    count_op NUMBER := 0;
    count_op_all NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM log_habitans' INTO count_op;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM logs' INTO count_op_all;
    curr_time := CURRENT_TIMESTAMP;
    CASE
        WHEN inserting THEN 
            INSERT INTO log_habitans VALUES (count_op+1,'INSERT',curr_time, :NEW.id, :NEW.type, :NEW.zoo_id);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'INSERT',curr_time,table_name);
        WHEN updating THEN 
            INSERT INTO log_habitans VALUES (count_op+1,'UPDATE',curr_time, :OLD.id, :OLD.type, :OLD.zoo_id);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'UPDATE',curr_time, table_name);
        WHEN deleting THEN 
            INSERT INTO log_habitans VALUES (count_op+1,'DELETE',curr_time, :OLD.id, :OLD.type, :OLD.zoo_id);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'DELETE',curr_time, table_name);
    END CASE;
    commit;
END;

CREATE OR REPLACE TRIGGER log_type
AFTER UPDATE OR INSERT OR DELETE ON type_habitans FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    curr_time TIMESTAMP;
    table_name VARCHAR2(15) := 'log_type';
    count_op NUMBER := 0;
    count_op_all NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM log_type' INTO count_op;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM logs' INTO count_op_all;
    curr_time := CURRENT_TIMESTAMP;
    CASE
        WHEN inserting THEN 
            INSERT INTO log_type VALUES (count_op+1,'INSERT',curr_time, :NEW.id, :NEW.name, :NEW.birthd, :NEW.type_id, :NEW.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'INSERT',curr_time,table_name);
        WHEN updating THEN 
            INSERT INTO log_type VALUES (count_op+1,'UPDATE',curr_time, :OLD.id, :OLD.name, :OLD.birthd, :OLD.type_id, :OLD.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'UPDATE',curr_time, table_name);
        WHEN deleting THEN 
            INSERT INTO log_type VALUES (count_op+1,'DELETE',curr_time, :OLD.id, :OLD.name, :OLD.birthd, :OLD.type_id, :OLD.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'DELETE',curr_time, table_name);
    END CASE;
    commit;
END;

CREATE OR REPLACE PACKAGE data_rollback_overload IS
    PROCEDURE data_rollback(to_date TIMESTAMP);
    PROCEDURE data_rollback(msc number);
    PROCEDURE create_report(to_date TIMESTAMP);
END data_rollback_overload;

SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE BODY data_rollback_overload IS
PROCEDURE data_rollback(to_date TIMESTAMP)
IS
BEGIN
    roll_back(TO_TIMESTAMP(to_date));
END data_rollback;
PROCEDURE data_rollback(msc number)
IS
BEGIN
    roll_back(TO_TIMESTAMP(CURRENT_TIMESTAMP - numToDSInterval( msc / 1000, 'second' )));
END data_rollback;
PROCEDURE create_report(to_date TIMESTAMP)
IS 
  file_handle UTL_FILE.FILE_TYPE;
  log_html VARCHAR2(10000);
BEGIN 
file_handle := UTL_FILE.FOPEN('BD5', 'my_file.html', 'W', 10000);
 log_html := '<html><head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
</style>
</head><body> <h1 style="text-align: center"> TYPE LIST </h1> 
<table style="width:100%" class="center">
  <tr align="center">
    <th align="center">OPERATION</th>
     <th align="center">OPERATION_TIME</th>
    <th align="center">ID</th>
    <th align="center">NAME</th>
    <th align="center">BIRTHD</th>
    <th align="center">TYPE_ID</th>
    <th align="center">COUNT_HABITANS</th>
  </tr>';
  for l_rec in (select * from log_type) loop
   IF(l_rec.times <= to_date) THEN
    log_html := log_html || '<tr align="center"> <td align="left">'|| l_rec.operation ||'</td> <td align="center">'
    ||l_rec.times ||'</td><td align="left">' || l_rec.id ||'</td><td align="left">' || l_rec.name 
    ||'</td><td align="left">' || l_rec.birthd 
    ||'</td><td align="left">' || l_rec.type_id
    ||'</td><td align="left">' || l_rec.count_habitans ||'</td> </tr>';
    END IF;
  end loop;
  log_html := log_html || '</table></body></html>';
  UTL_FILE.PUT_LINE(file_handle,log_html,true);
  DBMS_OUTPUT.PUT_LINE(log_html);
  log_html := '<html><head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
</style>
</head><body>
<h1 style="text-align: center"> HABITANS LIST </h1> 
<table style="width:100%" class="center">
  <tr align="center">
      <th align="center">OPERATION</th>
     <th align="center">OPERATION_TIME</th>
    <th align="center">ID</th>
     <th align="center">TYPE</th>
    <th align="center">ZOO_ID</th>
  </tr>';
  for l_rec in (select * from log_habitans) loop
    IF(l_rec.times <= to_date) THEN
    log_html := log_html || '<tr align="center"> <td align="left">'|| l_rec.operation ||'</td> <td align="center">'
    ||l_rec.times ||'</td><td align="left">' || l_rec.id ||'</td><td align="left">' || l_rec.type
    ||'</td><td align="left">' || l_rec.zoo_id ||'</td> </tr>';
    END IF;
  end loop;
  log_html := log_html || '</table>';
  log_html := log_html || '</body></html>';
  UTL_FILE.PUT_LINE(file_handle,log_html,true);
  DBMS_OUTPUT.PUT_LINE(log_html);
     log_html := '<html><head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
</style>
</head><body>
<h1 style="text-align: center"> ZOO LIST </h1> 
<table style="width:100%" class="center">
  <tr align="center">
      <th align="center">OPERATION</th>
     <th align="center">OPERATION_TIME</th>
    <th align="center">ID</th>
     <th align="center">NAME</th>
    <th align="center">CITY</th>
    <th align="center">COUNTRY</th>
  </tr>';
  for l_rec in (select * from log_zoo) loop
   IF(l_rec.times <= to_date) THEN
    log_html := log_html || '<tr align="center"> <td align="left">'|| l_rec.operation ||'</td> <td align="center">'
    ||l_rec.times ||'</td><td align="left">' || l_rec.id ||'</td><td align="left">' || l_rec.name 
    ||'</td><td align="left">' || l_rec.city || '</td><td align="left">' || l_rec.country ||'</td> </tr>';
    END IF;
  end loop;
  log_html := log_html || '</table>';
  log_html := log_html || '</body></html>';
  UTL_FILE.PUT_LINE(file_handle,log_html,true);
  DBMS_OUTPUT.PUT_LINE(log_html);
  UTL_FILE.FCLOSE(file_handle);
END;
END data_rollback_overload;

CREATE OR REPLACE PROCEDURE roll_back(time_back TIMESTAMP)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
CURSOR c_log_type(id NUMBER) IS SELECT * FROM log_type;
r_type log_type%rowtype;
CURSOR c_log_habitans(id NUMBER) IS SELECT * FROM log_habitans;
r_habitans log_habitans%rowtype;
CURSOR c_log_zoo(id NUMBER) IS SELECT * FROM log_zoo;
r_zoo log_zoo%rowtype;
CURSOR c_get_logs IS SELECT * FROM logs WHERE times > time_back order by times DESC;
wrong_operation EXCEPTION;
BEGIN
    FOR r_item IN c_get_logs LOOP
     IF r_item.times > time_back THEN 
        CASE r_item.table_name
            WHEN 'log_zoo' THEN 
              OPEN c_log_zoo(r_item.operation_id);
               FETCH c_log_zoo INTO r_zoo;
               dbms_output.put_line('log_zoo'|| ' ' ||r_zoo.operation ||r_zoo.operation_id);
                CASE r_zoo.operation
                    WHEN 'INSERT' THEN
                        DELETE FROM zooo WHERE id=r_zoo.id;
                    WHEN 'UPDATE' THEN
                        UPDATE zooo SET 
                            zooo.name=r_zoo.name,
                            zooo.city=r_zoo.city ,
                            zooo.country=r_zoo.country 
                            WHERE zooo.id=r_zoo.id;
                    WHEN 'DELETE' THEN
                        INSERT INTO zooo VALUES(r_zoo.id, r_zoo.name, r_zoo.city, r_zoo.country);
                END CASE;
              CLOSE c_log_zoo;
            WHEN 'log_habitans' THEN
             OPEN c_log_habitans(r_item.operation_id);
             FETCH c_log_habitans INTO r_habitans;
             dbms_output.put_line('log_habitans'|| ' ' || r_habitans.operation || r_habitans.operation_id);
                CASE r_habitans.operation
                WHEN 'INSERT' THEN
                  DELETE FROM zoo_habitans WHERE id=r_habitans.id;
                WHEN 'UPDATE' THEN
                    UPDATE zoo_habitans SET 
                        zoo_habitans.type=r_habitans.type,
                        zoo_habitans.zoo_id=r_habitans.zoo_id 
                        WHERE zoo_habitans.id=r_habitans.id;
                WHEN 'DELETE' THEN
                 INSERT INTO zoo_habitans VALUES(r_habitans.id, r_habitans.type, r_habitans.zoo_id);
                END CASE;
              CLOSE c_log_habitans;
            WHEN 'log_type' THEN
             OPEN c_log_type(r_item.operation_id);
              FETCH c_log_type INTO r_type;
                dbms_output.put_line('log_type'|| ' ' ||r_type.operation||r_type.operation_id);
                CASE r_type.operation
                WHEN 'INSERT' THEN
                  DELETE FROM type_habitans WHERE id=r_type.id;
                WHEN 'UPDATE' THEN
                    UPDATE type_habitans SET 
                        type_habitans.name=r_type.name,
                        type_habitans.birthd = r_type.birthd,
                        type_habitans.type_id = r_type.type_id,
                        type_habitans.count_habitans=r_type.count_habitans
                        WHERE type_habitans.id=r_type.id;
                WHEN 'DELETE' THEN
                 INSERT INTO type_habitans VALUES(r_type.id, r_type.name, r_type.birthd,  r_type.type_id, r_type.count_habitans);
                END CASE;
              CLOSE c_log_type;
            ELSE raise wrong_operation;
        END CASE;
      commit;
     END IF;      
    END LOOP;
END;
    
SELECT * FROM logs;

INSERT INTO zooo VALUES(1,'Zoo Minsk','Minsk','Belarus');
INSERT INTO zooo VALUES(2,'Zoo Grodno','Minsk','Belarus');
INSERT INTO zooo VALUES(3,'Zoo Brest','Brest','Belarus');
INSERT INTO zooo VALUES(4,'Zoo Gomel','Gomel','Belarus');
UPDATE zooo SET city='Grodno' WHERE id=2;
SELECT * FROM log_zoo;
SELECT * FROM zooo;

INSERT INTO zoo_habitans VALUES(1,1,'Mammals');
INSERT INTO zoo_habitans VALUES(2,2,'Birds');
INSERT INTO zoo_habitans VALUES(3,3,'Amphibians');
SELECT * FROM log_habitans;
SELECT * FROM zoo_habitans;

INSERT INTO type_habitans VALUES(1,'Elephants',to_date('05-11-2020','dd-mm-yyyy'),1,2);
INSERT INTO type_habitans VALUES(2,'Parrots',to_date('03-05-2022','dd-mm-yyyy'),2,12);
INSERT INTO type_habitans VALUES(3,'Snakes',to_date('17-02-2023','dd-mm-yyyy'),3,2);
INSERT INTO type_habitans VALUES(4,'Dogs',to_date('05-01-2022','dd-mm-yyyy'),1,20);
UPDATE type_habitans SET count_habitans=21 WHERE id=4;
SELECT * FROM log_type;
SELECT * FROM type_habitans;

BEGIN
    data_rollback_overload.data_rollback(TO_TIMESTAMP('03.05.23 17:02:35,241000000'));
    data_rollback_overload.create_report(TO_TIMESTAMP('03.05.23 17:02:35,241000000'));
END;
BEGIN
    data_rollback_overload.data_rollback(TO_TIMESTAMP('03.05.23 13:56:49,325000000'));
END;
