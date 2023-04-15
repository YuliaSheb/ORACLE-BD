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
