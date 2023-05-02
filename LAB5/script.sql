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
    type_id NUMBER,
    name VARCHAR2(15),
    count_habitans NUMBER,
    CONSTRAINT fk_zoo_type FOREIGN KEY (type_id) REFERENCES zoo_habitans(id)
    );
    
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
    
DROP TABLE logs;
    
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
            INSERT INTO log_zoo VALUES (count_op+1,'INSERT',curr_time, :NEW.id, :NEW.name, :NEW.type_id, :NEW.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'INSERT',curr_time,table_name);
        WHEN updating THEN 
            INSERT INTO log_zoo VALUES (count_op+1,'UPDATE',curr_time, :OLD.id, :OLD.name, :OLD.type_id, :OLD.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'UPDATE',curr_time, table_name);
        WHEN deleting THEN 
            INSERT INTO log_zoo VALUES (count_op+1,'DELETE',curr_time, :OLD.id, :OLD.name, :OLD.type_id, :OLD.count_habitans);
            INSERT INTO logs VALUES (count_op_all,count_op+1,'DELETE',curr_time, table_name);
    END CASE;
    commit;
END;

SELECT * FROM log_zoo;

INSERT INTO zooo VALUES(1,'Zoo Minsk','Minsk','Belarus');
    

    
