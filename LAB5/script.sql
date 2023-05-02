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
    operation VARCHAR2(15),
    times TIMESTAMP NOT NULL,
    table_name VARCHAR2(15)
    );
    

    
