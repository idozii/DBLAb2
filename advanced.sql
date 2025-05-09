-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
USE bank_management_system;

--! Views
-- View 1: Customer Account Summary provides view of each customer and their accounts
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

-- View 2: Transaction History shows transaction history with customer and account information
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

--! Procedures
-- Procedure 1: Transfer Money Between Accounts with Backup Logging
DELIMITER //
CREATE PROCEDURE transfer_money(
    IN source_account_id INT,
    IN target_account_id INT,
    IN transfer_amount DECIMAL(15,2),
    OUT status VARCHAR(100)
)
BEGIN
    DECLARE source_balance DECIMAL(15,2);
    DECLARE backup_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET status = 'Error occurred during transfer';
        
        SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (backup_id, NOW(), CONCAT('transfer_log_', source_account_id, '_to_', target_account_id), 'Failed');
    END;
    
    START TRANSACTION;
    
    SELECT Balance INTO source_balance FROM ACCOUNT WHERE Account_ID = source_account_id FOR UPDATE;
    
    IF source_balance < transfer_amount THEN
        SET status = 'Insufficient funds';
        
        SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (backup_id, NOW(), CONCAT('transfer_log_insufficient_funds_', source_account_id), 'Failed');
        
        ROLLBACK;
    ELSE
        UPDATE ACCOUNT SET Balance = Balance - transfer_amount WHERE Account_ID = source_account_id;
        
        UPDATE ACCOUNT SET Balance = Balance + transfer_amount WHERE Account_ID = target_account_id;
        
        INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
        VALUES (FLOOR(RAND()*10000) + 3000, 'Transfer to account', 'Transfer', NOW(), transfer_amount, source_account_id);
        
        INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
        VALUES (FLOOR(RAND()*10000) + 4000, 'Transfer from account', 'Deposit', NOW(), transfer_amount, target_account_id);
        
        SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (backup_id, NOW(), CONCAT('transfer_log_', source_account_id, '_to_', target_account_id), 'Success');
        
        COMMIT;
        SET status = 'Transfer successful';
    END IF;
END //
DELIMITER ;

-- Procedure 2: Create New Customer with Account with Backup Logging
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
    DECLARE backup_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_customer_id = 0;
        SET p_account_id = 0;
        
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (
            (SELECT COALESCE(MAX(Backup_ID), 0) + 1 FROM BACKUP_LOGS b),
            NOW(), 
            CONCAT('customer_creation_', p_f_name, '_', p_l_name), 
            'Failed'
        );
    END;
    
    START TRANSACTION;
    
    SELECT COALESCE(MAX(Customer_ID), 0) + 1 INTO p_customer_id FROM CUSTOMER;
    
    SELECT COALESCE(MAX(Account_ID), 0) + 1 INTO p_account_id FROM ACCOUNT;
    
    INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
    VALUES (p_customer_id, p_f_name, p_l_name, p_gender, p_email, p_address, p_phone, p_ssn, p_credit_score, p_dob);
    
    INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
    VALUES (p_account_id, CURRENT_DATE(), p_initial_deposit, p_account_type, p_credit_score, p_customer_id);
    
    INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
    VALUES (FLOOR(RAND()*10000) + 5000, 'Initial account deposit', 'Deposit', NOW(), p_initial_deposit, p_account_id);
    
    SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
    
    INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
    VALUES (backup_id, NOW(), CONCAT('customer_account_creation_', p_customer_id, '_', p_account_id), 'Success');
    
    COMMIT;
END //
DELIMITER ;

-- Procedure 3: Create a view backup procedure
DELIMITER //
CREATE PROCEDURE backup_database_views()
BEGIN
    DECLARE backup_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (backup_id, NOW(), 'database_views_backup', 'Failed');
    END;
    
    SELECT COALESCE(MAX(Backup_ID), 0) + 1 INTO backup_id FROM BACKUP_LOGS;
    INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
    VALUES (backup_id, NOW(), 'database_views_backup', 'Success');
    
    INSERT INTO AI_ADVISOR (Advisor_ID, Timestamp, Content, Advisor_Type)
    VALUES (
        FLOOR(RAND()*10000) + 1000,
        NOW(),
        'Database views have been successfully backed up. Regular backups help maintain system integrity.',
        'System Maintenance'
    );
END //
DELIMITER ;


--! Example for transfer_money procedure
SET @transfer_status = NULL;
CALL transfer_money(105, 106, 500.00, @transfer_status);
SELECT @transfer_status AS 'Transfer Result';

SELECT Account_ID, Balance, Account_Type FROM ACCOUNT WHERE Account_ID IN (105, 106);

SELECT * FROM TRANSACTION 
WHERE Account_ID IN (105, 106) 
ORDER BY Transaction_Time DESC LIMIT 4;

SELECT * FROM BACKUP_LOGS 
WHERE Filepath LIKE 'transfer_log_105_%' 
ORDER BY Timestamp DESC LIMIT 1;

--! Example for create_customer_with_account procedure
SET @new_customer_id = NULL;
SET @new_account_id = NULL;

CALL create_customer_with_account(
    'Jane',          
    'Johnson',         
    'Female',         
    'jane.johnson@example.com', 
    '456 Oak Street', 
    '555-9876',     
    '987-65-4321', 
    725,            
    '1990-03-22',   
    'Checking',     
    3000.00,        
    @new_customer_id, 
    @new_account_id  
);

SELECT @new_customer_id AS New_Customer_ID, @new_account_id AS New_Account_ID;

SELECT * FROM BACKUP_LOGS ORDER BY Timestamp DESC LIMIT 5;