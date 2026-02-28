CREATE TABLE IF NOT EXISTS interns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL
);

INSERT INTO interns (name, status) VALUES ('Nithin', 'Hired');
INSERT INTO interns (name, status) VALUES ('DevOps Bot', 'Active');