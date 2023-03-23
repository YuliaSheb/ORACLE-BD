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
