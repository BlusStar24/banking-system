CREATE SEQUENCE IF NOT EXISTS sequence START 1;

-- Tạo cơ sở dữ liệu
CREATE DATABASE bank_users;

-- Chuyển vào database vừa tạo
\c bank_users;

-- Bảng users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    cccd VARCHAR(20) NOT NULL,
    dob DATE NOT NULL,
    hometown VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(10),
    otp_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(50) NOT NULL,
    blacklisted BOOLEAN DEFAULT FALSE
);

-- Bảng blacklist
CREATE TABLE IF NOT EXISTS blacklist (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    blacklisted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng employee
CREATE TABLE IF NOT EXISTS employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    position VARCHAR(100),
    hired_date DATE,
    active BOOLEAN DEFAULT TRUE
);
