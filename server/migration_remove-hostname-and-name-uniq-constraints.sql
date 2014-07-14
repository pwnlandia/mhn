CREATE TABLE sensors2 (
	id INTEGER NOT NULL, 
	uuid VARCHAR(36), 
	name VARCHAR(50), 
	created_date DATETIME, 
	ip VARCHAR(15), 
	hostname VARCHAR(50), 
	identifier VARCHAR(50), 
	honeypot VARCHAR(50), 
	PRIMARY KEY (id), 
	UNIQUE (uuid), 
	UNIQUE (identifier)
);

INSERT INTO sensors2 (id, uuid, name, created_date, ip, hostname, identifier, honeypot)  
	SELECT id, uuid, name, created_date, ip, hostname, identifier, honeypot FROM sensors;
ALTER TABLE sensors RENAME TO sensors_backup;
ALTER TABLE sensors2 RENAME TO sensors;
