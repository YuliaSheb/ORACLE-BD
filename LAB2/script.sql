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
