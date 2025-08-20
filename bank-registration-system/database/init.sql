CREATE DATABASE IF NOT EXISTS bank_users;
USE bank_users;

-- 1. Customers (CIF)
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(36) PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    phone       VARCHAR(20) NOT NULL UNIQUE,
    cccd        VARCHAR(20) NOT NULL UNIQUE,
    dob         DATE NOT NULL,
    hometown    VARCHAR(255),
    email       VARCHAR(255),
    kyc_status  BOOLEAN DEFAULT FALSE,
    status      VARCHAR(20) DEFAULT 'pending', -- pending, active, frozen
    blacklisted BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE customers 
ADD COLUMN gender ENUM('male','female','other') NOT NULL AFTER dob;
ALTER TABLE customers ADD COLUMN cif VARCHAR(20) NULL;
CREATE UNIQUE INDEX ux_customers_cif ON customers(cif);

-- 2. OTP requests (độc lập, FK về customers)
CREATE TABLE IF NOT EXISTS otp_requests (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    customer_id  VARCHAR(36),
    otp_code     VARCHAR(10) NOT NULL,
    verified     BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at   TIMESTAMP,
    CONSTRAINT fk_otp_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

CREATE TABLE pin_codes (
    id SERIAL PRIMARY KEY,
    owner_type ENUM('user', 'account', 'card') NOT NULL,
    owner_id VARCHAR(36) NOT NULL,
    pin_hash TEXT NOT NULL,
    failed_attempts INT DEFAULT 0,
    is_locked BOOLEAN DEFAULT FALSE,
    last_changed TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Users (login, liên kết với customers)
CREATE TABLE IF NOT EXISTS users (
    user_id           VARCHAR(36) PRIMARY KEY,
    username          VARCHAR(50) UNIQUE,
    password_hash     VARCHAR(255),
    role              VARCHAR(20) DEFAULT 'customer', -- admin, customer
    linked_customer_id VARCHAR(36),
    CONSTRAINT fk_user_customer FOREIGN KEY (linked_customer_id)
        REFERENCES customers(customer_id)
        ON DELETE SET NULL
);

-- 4. Blacklist (các khách hàng bị cấm)
CREATE TABLE IF NOT EXISTS blacklist (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(36),
    reason TEXT,
    blacklisted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_blacklist_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- 5. Accounts
CREATE TABLE IF NOT EXISTS accounts (
    account_id VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36),
    type VARCHAR(20),
    label VARCHAR(100),
    balance DECIMAL(18,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'VND',
    bank_code VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);
ALTER TABLE accounts ADD COLUMN account_number VARCHAR(50);

-- 6. Transactions
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(36) PRIMARY KEY,
    from_account_id VARCHAR(36),
    to_account_id   VARCHAR(36),
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    description VARCHAR(2000),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tx_from FOREIGN KEY (from_account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tx_to FOREIGN KEY (to_account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE
);

-- 7. Transaction requests (OTP cho giao dịch)
CREATE TABLE IF NOT EXISTS transaction_requests (
    request_id       VARCHAR(36) PRIMARY KEY,
    from_account_id  VARCHAR(36),
    to_account_id    VARCHAR(36),
    amount           DECIMAL(18,2) NOT NULL,
    currency         VARCHAR(3) DEFAULT 'VND',
    description      VARCHAR(2000),
    otp_code         VARCHAR(10),
    otp_verified     BOOLEAN DEFAULT FALSE,
    status           VARCHAR(20) DEFAULT 'initiated',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_req_from FOREIGN KEY (from_account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_req_to FOREIGN KEY (to_account_id)
        REFERENCES accounts(account_id)
        ON DELETE CASCADE
);

-- 8. Employees
CREATE TABLE IF NOT EXISTS employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    position VARCHAR(100),
    hired_date DATE,
    active BOOLEAN DEFAULT TRUE
);

-- 9. Refresh Tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id SERIAL PRIMARY KEY,
    token TEXT NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);
