USE bank_users;

-- ===== 0) Chuẩn bị & dọn rác cũ =====
SET @from  = '0a09525c-b448-4a8b-979d-73805d54b860'; -- TK nguồn có sẵn trong dump
SET @to    = '32ee1af4-7ecc-4c50-8dc3-691adc501874'; -- TK đích nội bộ
SET @ccy   = 'VND';

-- Xoá dữ liệu test cũ (nếu có)
DELETE FROM ledger_entries WHERE transaction_id IN (SELECT transaction_id FROM transactions WHERE description LIKE 'TEST%');
DELETE FROM refunds         WHERE reason LIKE 'TEST%';
DELETE FROM transactions    WHERE description LIKE 'TEST%';

SELECT account_id, balance FROM accounts WHERE account_id IN (@from, @to, 'external_liability');

-- ===== 1) INTERNAL: happy path =====
SET @tx_int = REPLACE(UUID(),'-','');
SET @req_int = 'REQ_INT_OK_001';
CALL sp_transfer_internal(
  @tx_int, @from, @to, 1000.00, @ccy, 'TEST INTERNAL OK', @req_int,
  @err1, @det1
);
SELECT 'INT_OK' AS step, @err1 AS err, @det1 AS detail;
SELECT account_id, balance FROM accounts WHERE account_id IN (@from, @to);
SELECT t.transaction_id, t.type, t.status, t.amount FROM transactions t WHERE t.transaction_id=@tx_int;
SELECT account_id, direction, amount FROM ledger_entries WHERE transaction_id=@tx_int ORDER BY posted_at;

-- ===== 2) INTERNAL: idempotency (không tạo lại) =====
SET @tx_int_dup = REPLACE(UUID(),'-','');
CALL sp_transfer_internal(
  @tx_int_dup, @from, @to, 1000.00, @ccy, 'TEST INTERNAL IDEMP', @req_int,
  @err2, @det2
);
SELECT 'INT_IDEMP' AS step, @err2 AS err, @det2 AS detail;
SELECT * FROM transactions WHERE transaction_id IN (@tx_int, @tx_int_dup);

-- ===== 3) INTERNAL: insufficient funds =====
SET @tx_int_big = REPLACE(UUID(),'-','');
CALL sp_transfer_internal(
  @tx_int_big, @from, @to, 999999999.00, @ccy, 'TEST INTERNAL NO MONEY', 'REQ_INT_NO_MONEY',
  @err3, @det3
);
SELECT 'INT_NO_MONEY' AS step, @err3 AS err, @det3 AS detail;

-- ===== 4) INTERNAL: sender blacklist =====
SELECT customer_id INTO @from_cust FROM accounts WHERE account_id=@from;
UPDATE customers SET blacklisted=1 WHERE customer_id=@from_cust;

SET @tx_int_blk = REPLACE(UUID(),'-','');
CALL sp_transfer_internal(
  @tx_int_blk, @from, @to, 100.00, @ccy, 'TEST INTERNAL BLACKLIST', 'REQ_INT_BLACK_1',
  @err4, @det4
);
SELECT 'INT_BLACKLIST' AS step, @err4 AS err, @det4 AS detail;

UPDATE customers SET blacklisted=0 WHERE customer_id=@from_cust; -- gỡ cờ

-- ===== 5) EXTERNAL: request (post vào clearing) =====
SELECT account_id, balance FROM accounts WHERE account_id IN (@from, 'external_liability');

SET @tx_ext  = REPLACE(UUID(),'-','');
SET @req_e1  = 'REQ_EXT_OK_001';
CALL sp_transfer_external_request(
  @tx_ext, @from, 'VCB', '9704-EXT-1234567', 'NGUYEN VAN A', 2000.00, @ccy,
  'TEST EXTERNAL REQUEST', @req_e1,
  @err5, @det5
);
SELECT 'EXT_REQ_OK' AS step, @err5 AS err, @det5 AS detail;
SELECT account_id, balance FROM accounts WHERE account_id IN (@from, 'external_liability');
SELECT transaction_id, type, status, amount, to_bank_id FROM transactions WHERE transaction_id=@tx_ext;
SELECT account_id, direction, amount FROM ledger_entries WHERE transaction_id=@tx_ext ORDER BY posted_at;

-- ===== 6) EXTERNAL: settlement THÀNH CÔNG =====
CALL sp_transfer_external_settle(@tx_ext, 1, NULL, NULL);
SELECT 'EXT_SETTLE_OK' AS step;
SELECT transaction_id, status FROM transactions WHERE transaction_id=@tx_ext;
SELECT account_id, balance FROM accounts WHERE account_id='external_liability';
SELECT account_id, direction, amount FROM ledger_entries WHERE transaction_id=@tx_ext ORDER BY posted_at;

-- ===== 7) EXTERNAL: settlement THẤT BẠI (hoàn tiền) =====
SET @tx_ext_fail = REPLACE(UUID(),'-','');
SET @req_e2      = 'REQ_EXT_FAIL_001';
CALL sp_transfer_external_request(
  @tx_ext_fail, @from, 'TCB', '9704-EXT-7654321', 'TRAN THI B', 1500.00, @ccy,
  'TEST EXTERNAL REQUEST FAIL', @req_e2,
  @err6, @det6
);
SELECT 'EXT_REQ_FAIL_CASE' AS step, @err6 AS err, @det6 AS detail;

CALL sp_transfer_external_settle(@tx_ext_fail, 0, 'BANK_DECLINED', 'Insufficient funds at destination');
SELECT 'EXT_SETTLE_FAIL' AS step;
SELECT transaction_id, status, failure_code, failure_detail FROM transactions WHERE transaction_id=@tx_ext_fail;
SELECT account_id, balance FROM accounts WHERE account_id IN (@from, 'external_liability');
SELECT * FROM refunds WHERE transaction_id=@tx_ext_fail;
SELECT account_id, direction, amount FROM ledger_entries WHERE transaction_id=@tx_ext_fail ORDER BY posted_at;

-- ===== 8) EXTERNAL: idempotency (request trùng client_request_id) =====
SET @tx_ext_dup = REPLACE(UUID(),'-','');
CALL sp_transfer_external_request(
  @tx_ext_dup, @from, 'TCB', '9704-EXT-7654321', 'TRAN THI B', 1500.00, @ccy,
  'TEST EXTERNAL IDEMP', @req_e2,
  @err7, @det7
);
SELECT 'EXT_REQ_IDEMP' AS step, @err7 AS err, @det7 AS detail;

-- ===== 9) Tổng hợp kết quả test =====
SELECT transaction_id, type, status, amount, description, created_at
FROM transactions WHERE description LIKE 'TEST%' ORDER BY created_at DESC;

SELECT t.transaction_id,
       COUNT(*) AS entries,
       SUM(direction='DEBIT')  AS debits,
       SUM(direction='CREDIT') AS credits
FROM transactions t
JOIN ledger_entries l ON l.transaction_id = t.transaction_id
WHERE t.description LIKE 'TEST%'
GROUP BY t.transaction_id
ORDER BY t.transaction_id;

SELECT account_id, balance FROM accounts WHERE account_id IN (@from, @to, 'external_liability');
