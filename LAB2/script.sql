CREATE TABLE students (
id NUMBER,
name VARCHAR2(15),
group_id NUMBER
);

CREATE TABLE groupss (
id NUMBER,
name VARCHAR2(15),
c_val NUMBER
);

INSERT INTO Students(id,name,group_id) VALUES (1, 'Yulia', 1);
INSERT INTO Students(id,name,group_id) VALUES (2, 'Veronika', 1);
INSERT INTO Students(id,name,group_id) VALUES (3, 'Tanya', 1);
INSERT INTO Students(id,name,group_id) VALUES (4, 'Nikita', 2);
INSERT INTO Students(id,name,group_id) VALUES (5, 'Lera', 2);
INSERT INTO Students(id,name,group_id) VALUES (6, 'Vlad', 2);
INSERT INTO Students(id,name,group_id) VALUES (7, 'Misha', 3);
INSERT INTO Students(id,name,group_id) VALUES (8, 'Denis', 3);
INSERT INTO Students(id,name,group_id) VALUES (9, 'Arseniy', 3);
INSERT INTO Students(id,name,group_id) VALUES (10, 'Roma', 4);
INSERT INTO Students(id,name,group_id) VALUES (11, 'Oleg', 5);

INSERT INTO groupps(id,name,c_val) VALUES (1, '053501', 3);
INSERT INTO groupps(id,name,c_val) VALUES (2, '053502', 3);
INSERT INTO groupps(id,name,c_val) VALUES (3, '053503', 3);
INSERT INTO groupps(id,name,c_val) VALUES (4, '053504', 1);
INSERT INTO groupps(id,name,c_val) VALUES (5, '053505', 1);

CREATE OR REPLACE TRIGGER uniqueIdStudents
BEFORE INSERT OR UPDATE OF id ON student
FOR EACH ROW
DECLARE 
    n_id NUMBER;
BEGIN
    SELECT count(*) INTO n_id FROM student WHERE student.id =: new.id;
    IF n_id > 0 THEN raise_application_error(-20000, 'It is not unique id');
    ELSE dbms_output.put_line(' Succes');
    END IF;
END;

CREATE OR REPLACE TRIGGER uniqueNameGroups
BEFORE INSERT OR UPDATE ON groupps
FOR EACH ROW
DECLARE 
    n_name NUMBER;
BEGIN
    SELECT count(*) INTO n_name FROM groupps WHERE groupps.name =: new.name;
    IF n_name > 0 THEN raise_application_error(-20000, 'It is not unique group_name');
    ELSE dbms_output.put_line(' Succes');
    END IF;
END;

CREATE OR REPLACE TRIGGER autoIncrementIdStudents
BEFORE INSERT ON student
FOR EACH ROW
DECLARE 
    max_id NUMBER := 0;
BEGIN
    SELECT max(student.id) INTO max_id FROM student;
    IF max_id is null THEN max_id := 0;
    END IF;
    :new.id := max_id + 1;
END;

INSERT INTO student(name,group_id) VALUES ('Sasha', 4);

CREATE OR REPLACE TRIGGER autoIncrementIdGroups
BEFORE INSERT ON groupps
FOR EACH ROW
DECLARE 
    max_id NUMBER := 0;
BEGIN
    SELECT max(groupps.id) INTO max_id FROM groupps;
    IF max_id is null THEN max_id := 0;
    END IF;
    :new.id := max_id + 1;
END;

INSERT INTO groupps(name,c_val) VALUES ('050502', 0);

CREATE OR REPLACE TRIGGER cascadeDelete
BEFORE DELETE ON groupps
FOR EACH ROW
BEGIN
    DELETE FROM student WHERE group_id=:old.id;
END;

INSERT INTO student(name,group_id) VALUES ('Vika', 6);

DELETE FROM groupps WHERE id=6;

CREATE TABLE log_student (
id NUMBER PRIMARY KEY,
operation VARCHAR2(10) NOT NULL,
student_id NUMBER,
student_name VARCHAR2(15) NOT NULL,
student_group_id NUMBER,
date_time timestamp
);

CREATE OR REPLACE TRIGGER autoIncrementIdLog
BEFORE INSERT ON log_student
FOR EACH ROW
DECLARE 
    max_id NUMBER := 0;
BEGIN
    SELECT max(id) INTO max_id FROM log_student;
    IF max_id is null THEN max_id := 0;
    END IF;
    :new.id := max_id + 1;
END;

CREATE OR REPLACE TRIGGER logStudent
BEFORE DELETE OR UPDATE OR INSERT ON student
FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO log_student(operation, student_id, student_name, student_group_id, date_time) 
            VALUES ('INSERT', :new.id, :new.name, :new.group_id, current_timestamp);
    ELSIF updating THEN
        INSERT INTO log_student(operation, student_id, student_name, student_group_id, date_time) 
            VALUES ('UPDATE', :new.id, :new.name, :new.group_id, current_timestamp);
     ELSIF deleting THEN
        INSERT INTO log_student(operation, student_id, student_name, student_group_id, date_time) 
            VALUES ('DELETE', :old.id, :old.name, :old.group_id, current_timestamp);
    END IF;
END;

SELECT * FROM log_student;

CREATE OR REPLACE PROCEDURE RestoreStudent(old_time timestamp) IS 
BEGIN
    FOR l IN (SELECT * FROM log_student WHERE date_time > old_time ORDER BY date_time DESC)
    LOOP
        CASE l.operation 
            WHEN 'INSERT' THEN
                DELETE FROM student WHERE id=l.student_id;
            WHEN 'UPDATE' THEN
                UPDATE student SET id = l.old_student_id,
                    name = l.old_student_name,
                    group_id = l.old_student_group_id
                WHERE id=l.student_id;
            WHEN 'DELETE' THEN
                INSERT INTO student(id,name,group_id) VALUES (l.old_student_id, l.old_student_name, l.old_student_group_id);
        END CASE;
    END LOOP;
END;

BEGIN
    RestoreStudent(TO_TIMESTAMP('23.03.23 20:55:20'));
END;

CREATE OR REPLACE TRIGGER changeValue
BEFORE DELETE OR UPDATE OR INSERT ON student
FOR EACH ROW
DECLARE
    students_in_group NUMBER;
BEGIN
    IF inserting THEN
        UPDATE groupps SET c_val = c_val+1 WHERE groupps.id = :new.group_id;
    ELSIF updating THEN
        IF :new.group_id != :old.group_id THEN
            UPDATE groupps SET c_val = c_val-1 WHERE groupps.id =: old.group_id;
            UPDATE groupps SET c_val = c_val+1 WHERE groupps.id = :new.group_id;
        END IF;
    ELSIF deleting THEN
        UPDATE groupps SET c_val = c_val-1 WHERE groupps.id =: old.group_id;
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('the group has been deleted');
END;
