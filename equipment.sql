-- equipment.sql - SQL script for creating "equipment" table and loading it
-- Copyright (C) 1995  David A. Snyder  All Rights Reserved


CREATE TABLE equipment
  (
    eq_id SERIAL NOT NULL,
    eqp_name CHAR(20),
    parent_eq_id INTEGER,
    PRIMARY KEY (eq_id) CONSTRAINT pk_eqid,
    UNIQUE (eqp_name) CONSTRAINT u_eqpname,
    CHECK (eq_id != parent_eq_id) CONSTRAINT eqid_ne_peqid
  );

ALTER TABLE equipment ADD CONSTRAINT
  (FOREIGN KEY (parent_eq_id) REFERENCES equipment CONSTRAINT fk_peqid);

LOAD FROM "equipment.unl" INSERT INTO equipment;
