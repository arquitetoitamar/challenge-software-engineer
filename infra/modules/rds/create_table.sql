CREATE TABLE IF NOT EXISTS proposals (
    id SERIAL PRIMARY KEY,
    proposal_id UUID NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    proposal_value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
