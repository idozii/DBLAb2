-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
USE bank_management_system;

-- =========================================
-- VIEWS
-- =========================================

-- View 1: Customer Account Summary
-- Provides a consolidated view of each customer and their accounts
CREATE OR REPLACE VIEW customer_account_summary AS
SELECT 
    c.Customer_ID, 
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name,
    c.Email,
    c.Credit_Score,
    COUNT(a.Account_ID) AS Number_Of_Accounts,
    SUM(a.Balance) AS Total_Balance
FROM CUSTOMER c
LEFT JOIN ACCOUNT a ON c.Customer_ID = a.Customer_ID
GROUP BY c.Customer_ID, Customer_Name, c.Email, c.Credit_Score;

-- Example query using the view
SELECT * FROM customer_account_summary WHERE Total_Balance > 5000;

-- View 2: Transaction History
-- Shows detailed transaction history with customer and account information
CREATE OR REPLACE VIEW transaction_history AS
SELECT 
    t.Transaction_ID,
    t.Transaction_Time,
    t.Transaction_Type,
    t.Amount,
    t.Description,
    a.Account_ID,
    a.Account_Type,
    c.Customer_ID,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name
FROM TRANSACTION t
JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID;

-- Example query using the view
SELECT * FROM transaction_history 
WHERE Transaction_Type = 'Deposit' 
ORDER BY Transaction_Time DESC LIMIT 10;

-- =========================================
-- STORED PROCEDURES
-- =========================================

-- Procedure 1: Transfer Money Between Accounts
DELIMITER //
CREATE PROCEDURE transfer_money(
    IN source_account_id INT,
    IN target_account_id INT,
    IN transfer_amount DECIMAL(15,2),
    OUT status VARCHAR(100)
)
BEGIN
    DECLARE source_balance DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET status = 'Error occurred during transfer';
    END;
    
    START TRANSACTION;
    
    -- Check if source account has sufficient funds
    SELECT Balance INTO source_balance FROM ACCOUNT WHERE Account_ID = source_account_id FOR UPDATE;
    
    IF source_balance < transfer_amount THEN
        SET status = 'Insufficient funds';
        ROLLBACK;
    ELSE
        -- Update source account balance
        UPDATE ACCOUNT SET Balance = Balance - transfer_amount WHERE Account_ID = source_account_id;
        
        -- Update target account balance
        UPDATE ACCOUNT SET Balance = Balance + transfer_amount WHERE Account_ID = target_account_id;
        
        -- Log the transaction from source account
        INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
        VALUES (FLOOR(RAND()*10000) + 3000, 'Transfer to account', 'Transfer', NOW(), transfer_amount, source_account_id);
        
        -- Log the transaction to target account
        INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
        VALUES (FLOOR(RAND()*10000) + 4000, 'Transfer from account', 'Deposit', NOW(), transfer_amount, target_account_id);
        
        COMMIT;
        SET status = 'Transfer successful';
    END IF;
END //
DELIMITER ;

-- Example call
SET @transfer_status = '';
CALL transfer_money(105, 106, 500.00, @transfer_status);
SELECT @transfer_status;

-- Procedure 2: Create New Customer with Account
DELIMITER //
CREATE PROCEDURE create_customer_with_account(
    IN p_f_name VARCHAR(50),
    IN p_l_name VARCHAR(50),
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_email VARCHAR(100),
    IN p_address TEXT,
    IN p_phone VARCHAR(20),
    IN p_ssn VARCHAR(20),
    IN p_credit_score INT,
    IN p_dob DATE,
    IN p_account_type VARCHAR(50),
    IN p_initial_deposit DECIMAL(15,2),
    OUT p_customer_id INT,
    OUT p_account_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_customer_id = 0;
        SET p_account_id = 0;
    END;
    
    START TRANSACTION;
    
    -- Generate new IDs
    SELECT COALESCE(MAX(Customer_ID), 0) + 1 INTO p_customer_id FROM CUSTOMER;
    SELECT COALESCE(MAX(Account_ID), 0) + 1 INTO p_account_id FROM ACCOUNT;
    
    -- Insert customer
    INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
    VALUES (p_customer_id, p_f_name, p_l_name, p_gender, p_email, p_address, p_phone, p_ssn, p_credit_score, p_dob);
    
    -- Insert account
    INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
    VALUES (p_account_id, CURRENT_DATE(), p_initial_deposit, p_account_type, p_credit_score, p_customer_id);
    
    -- Log initial deposit transaction
    INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
    VALUES (FLOOR(RAND()*10000) + 5000, 'Initial account deposit', 'Deposit', NOW(), p_initial_deposit, p_account_id);
    
    COMMIT;
END //
DELIMITER ;

-- Example call
SET @new_customer_id = 0;
SET @new_account_id = 0;
CALL create_customer_with_account('Sarah', 'Johnson', 'Female', 'sarah.j@example.com', 
    '789 Pine St, Banking City', '555-9876', '321-65-8974', 720, '1990-03-15',
    'Premium Savings', 10000.00, @new_customer_id, @new_account_id);
SELECT @new_customer_id, @new_account_id;

-- =========================================
-- TRIGGERS
-- =========================================

-- Trigger 1: Update Account Balance After Transaction
DELIMITER //
CREATE TRIGGER after_transaction_insert
AFTER INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
    IF NEW.Transaction_Type = 'Deposit' THEN
        UPDATE ACCOUNT SET Balance = Balance + NEW.Amount WHERE Account_ID = NEW.Account_ID;
    ELSEIF NEW.Transaction_Type = 'Withdrawal' THEN
        UPDATE ACCOUNT SET Balance = Balance - NEW.Amount WHERE Account_ID = NEW.Account_ID;
    END IF;
    -- Transfers are handled by the transfer_money procedure
END //
DELIMITER ;

-- Trigger 2: Prevent Overdraft
DELIMITER //
CREATE TRIGGER before_transaction_insert
BEFORE INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);
    
    IF NEW.Transaction_Type = 'Withdrawal' THEN
        SELECT Balance INTO current_balance FROM ACCOUNT WHERE Account_ID = NEW.Account_ID;
        IF current_balance < NEW.Amount THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds for withdrawal';
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger 3: Sync Credit Score between CUSTOMER and ACCOUNT tables
DELIMITER //
CREATE TRIGGER after_customer_credit_update
AFTER UPDATE ON CUSTOMER
FOR EACH ROW
BEGIN
    IF OLD.Credit_Score != NEW.Credit_Score THEN
        UPDATE ACCOUNT SET Credit_Score = NEW.Credit_Score WHERE Customer_ID = NEW.Customer_ID;
    END IF;
END //
DELIMITER ;

-- Trigger 4: Track Last Login
DELIMITER //
CREATE TRIGGER before_customer_login_update
BEFORE UPDATE ON CUSTOMER_LOGIN
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Active' AND OLD.Status = 'Inactive' THEN
        SET NEW.Last_Login = NOW();
    END IF;
END //
DELIMITER ;

-- =========================================
-- TRANSACTIONS
-- =========================================

-- Complex Transaction Example: Close an Account and Transfer Balance
START TRANSACTION;

-- Variables for the example
SET @account_to_close = 109;
SET @transfer_destination = 108;
SET @customer_id = (SELECT Customer_ID FROM ACCOUNT WHERE Account_ID = @account_to_close);
SET @closing_balance = (SELECT Balance FROM ACCOUNT WHERE Account_ID = @account_to_close);

-- 1. Transfer the remaining balance
INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES (9001, 'Account closing - balance transfer out', 'Transfer', NOW(), @closing_balance, @account_to_close);

INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES (9002, 'Account closing - balance transfer in', 'Deposit', NOW(), @closing_balance, @transfer_destination);

-- 2. Update the destination account balance
UPDATE ACCOUNT 
SET Balance = Balance + @closing_balance 
WHERE Account_ID = @transfer_destination;

-- 3. Update the account to be closed
UPDATE ACCOUNT 
SET Balance = 0 
WHERE Account_ID = @account_to_close;

-- 4. Delete cards associated with the account
DELETE FROM CARD WHERE Account_ID = @account_to_close;

-- 5. Create a record in a new ACCOUNT_CLOSING table (we'll create this first)
CREATE TABLE IF NOT EXISTS ACCOUNT_CLOSING (
    Closing_ID INT AUTO_INCREMENT PRIMARY KEY,
    Account_ID INT,
    Closing_Date DATE,
    Closing_Reason VARCHAR(255),
    Final_Balance DECIMAL(15,2),
    Customer_ID INT
);

INSERT INTO ACCOUNT_CLOSING (Account_ID, Closing_Date, Closing_Reason, Final_Balance, Customer_ID)
VALUES (@account_to_close, CURRENT_DATE(), 'Customer Request', @closing_balance, @customer_id);

-- Commit the transaction
COMMIT;

-- =========================================
-- ADVANCED QUERIES WITH WINDOW FUNCTIONS & CTEs
-- =========================================

-- Common Table Expression (CTE) with Window Functions
-- Analyze customer transaction patterns
WITH TransactionSummary AS (
    SELECT 
        a.Customer_ID,
        CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name,
        t.Transaction_Type,
        COUNT(*) AS Transaction_Count,
        SUM(t.Amount) AS Total_Amount,
        AVG(t.Amount) AS Avg_Amount,
        RANK() OVER (PARTITION BY t.Transaction_Type ORDER BY SUM(t.Amount) DESC) as Type_Rank
    FROM TRANSACTION t
    JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
    JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
    GROUP BY a.Customer_ID, Customer_Name, t.Transaction_Type
)
SELECT 
    Customer_ID,
    Customer_Name,
    Transaction_Type,
    Transaction_Count,
    Total_Amount,
    Avg_Amount
FROM TransactionSummary
WHERE Type_Rank <= 3
ORDER BY Transaction_Type, Type_Rank;

-- Advanced Analytics: Running Balances by Account
SELECT 
    t.Transaction_ID,
    t.Transaction_Time,
    a.Account_ID,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name,
    t.Transaction_Type,
    t.Amount,
    CASE 
        WHEN t.Transaction_Type = 'Deposit' THEN t.Amount
        WHEN t.Transaction_Type = 'Withdrawal' THEN -t.Amount
        WHEN t.Transaction_Type = 'Transfer' THEN -t.Amount -- Simplified; transfers need more context
    END AS Amount_Impact,
    SUM(CASE 
        WHEN t.Transaction_Type = 'Deposit' THEN t.Amount
        WHEN t.Transaction_Type = 'Withdrawal' THEN -t.Amount
        WHEN t.Transaction_Type = 'Transfer' THEN -t.Amount
    END) OVER (PARTITION BY a.Account_ID ORDER BY t.Transaction_Time) AS Running_Balance
FROM TRANSACTION t
JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
ORDER BY a.Account_ID, t.Transaction_Time;

-- =========================================
-- FULL-TEXT SEARCH
-- =========================================

-- Add fulltext index to transaction descriptions
ALTER TABLE TRANSACTION ADD FULLTEXT(Description);

-- Example full-text search query
SELECT 
    t.Transaction_ID,
    t.Description,
    t.Transaction_Time,
    t.Amount,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name
FROM TRANSACTION t
JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
WHERE MATCH(t.Description) AGAINST('deposit bonus' IN NATURAL LANGUAGE MODE)
ORDER BY t.Transaction_Time DESC;