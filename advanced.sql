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
    DECLARE new_transaction_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_customer_id = 0;
        SET p_account_id = 0;
        INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
        VALUES (NOW(), CONCAT('customer_creation_', p_f_name, '_', p_l_name), 'Failed');
    END;

    START TRANSACTION;

    SELECT COALESCE(MAX(Customer_ID), 0) + 1 INTO p_customer_id FROM CUSTOMER;
    SELECT COALESCE(MAX(Account_ID), 0) + 1 INTO p_account_id FROM ACCOUNT;
    SELECT COALESCE(MAX(Transaction_ID), 0) + 1 INTO new_transaction_id FROM TRANSACTION;

    INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
    VALUES (p_customer_id, p_f_name, p_l_name, p_gender, p_email, p_address, p_phone, p_ssn, p_credit_score, p_dob);

    INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
    VALUES (p_account_id, CURRENT_DATE(), p_initial_deposit, p_account_type, p_credit_score, p_customer_id);

    INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
    VALUES (new_transaction_id, 'Initial account deposit', 'Deposit', NOW(), p_initial_deposit, p_account_id);

    INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
    VALUES (NOW(), CONCAT('customer_account_creation_', p_customer_id, '_', p_account_id), 'Success');

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

-- Procedure 4: Issue New Card
DELIMITER //
CREATE PROCEDURE issue_new_card(
    IN p_account_id INT,
    IN p_card_type VARCHAR(20),
    OUT p_card_id INT
)
BEGIN
    DECLARE card_number VARCHAR(20);
    DECLARE expiry_date DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_card_id = 0;
        INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
        VALUES (NOW(), CONCAT('card_issuance_', p_account_id), 'Failed');
    END;

    START TRANSACTION;

    SELECT COALESCE(MAX(Card_ID), 0) + 1 INTO p_card_id FROM CARD;
    SET card_number = CONCAT('4', LPAD(FLOOR(RAND()*1000000000000000), 15, '0'));
    SET expiry_date = DATE_ADD(CURRENT_DATE(), INTERVAL 3 YEAR);

    INSERT INTO CARD (Card_ID, Card_Number, Expiry_Date, Card_Type, Card_Status, Account_ID)
    VALUES (p_card_id, card_number, expiry_date, p_card_type, 'Active', p_account_id);

    INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
    VALUES (NOW(), CONCAT('card_issuance_', p_card_id, '_', p_account_id), 'Success');

    COMMIT;
END //
DELIMITER ;

-- Procedure 5: Apply for Loan
DELIMITER //
CREATE PROCEDURE apply_for_loan(
    IN p_account_id INT,
    IN p_loan_amount DECIMAL(15,2),
    IN p_loan_type VARCHAR(50),
    IN p_term_months INT,
    OUT p_loan_id INT,
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    DECLARE credit_score INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_loan_id = 0;
        SET p_status = 'Failed';
        INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
        VALUES (NOW(), CONCAT('loan_application_', p_account_id), 'Failed');
    END;

    START TRANSACTION;

    SELECT COALESCE(MAX(Loan_ID), 0) + 1 INTO p_loan_id FROM LOAN;

    SELECT Credit_Score INTO credit_score FROM ACCOUNT WHERE Account_ID = p_account_id;

    SET start_date = CURRENT_DATE();
    SET end_date = DATE_ADD(start_date, INTERVAL p_term_months MONTH);

    IF credit_score >= 650 THEN
        INSERT INTO LOAN (Loan_ID, Loan_Amount, Loan_Type, Start_Date, End_Date, Loan_Status, Account_ID)
        VALUES (p_loan_id, p_loan_amount, p_loan_type, start_date, end_date, 'Approved', p_account_id);
        SET p_status = 'Approved';
    ELSE
        INSERT INTO LOAN (Loan_ID, Loan_Amount, Loan_Type, Start_Date, End_Date, Loan_Status, Account_ID)
        VALUES (p_loan_id, p_loan_amount, p_loan_type, start_date, end_date, 'Rejected', p_account_id);
        SET p_status = 'Rejected';
    END IF;

    INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
    VALUES (NOW(), CONCAT('loan_application_', p_loan_id, '_', p_account_id), 'Success');

    COMMIT;
END //
DELIMITER ;

-- Procedure 6: Add a new branch
DELIMITER //
CREATE PROCEDURE add_new_branch(
    IN p_branch_name VARCHAR(100),
    IN p_address TEXT,
    OUT p_branch_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_branch_id = 0;
        INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
        VALUES (NOW(), CONCAT('branch_creation_', p_branch_name), 'Failed');
    END;

    START TRANSACTION;

    SELECT COALESCE(MAX(Branch_ID), 0) + 1 INTO p_branch_id FROM BRANCH;

    INSERT INTO BRANCH (Branch_ID, Branch_Name, Address)
    VALUES (p_branch_id, p_branch_name, p_address);

    INSERT INTO BACKUP_LOGS (Timestamp, Filepath, Status)
    VALUES (NOW(), CONCAT('branch_creation_', p_branch_id), 'Success');

    COMMIT;
END //
DELIMITER ;

-- Procedure 7: Add an AI advisor notification
DELIMITER //
CREATE PROCEDURE add_ai_advisor_message(
    IN p_content TEXT,
    IN p_advisor_type VARCHAR(50),
    OUT p_advisor_id INT
)
BEGIN
    SELECT COALESCE(MAX(Advisor_ID), 0) + 1 INTO p_advisor_id FROM AI_ADVISOR;

    INSERT INTO AI_ADVISOR (Advisor_ID, Timestamp, Content, Advisor_Type)
    VALUES (
        p_advisor_id,
        NOW(),
        p_content,
        p_advisor_type
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
    'Alice',               
    'Smith',               
    'Female',             
    'alice.smith@example.com', 
    '123 Oak Avenue',   
    '555-4321',         
    '321-54-9876',         
    780,                    
    '1991-08-22',          
    'Savings',            
    2500.00,             
    @new_customer_id,      
    @new_account_id         
);

SELECT @new_customer_id AS New_Customer_ID, @new_account_id AS New_Account_ID;
SELECT * FROM CUSTOMER WHERE Customer_ID = @new_customer_id;
SELECT * FROM ACCOUNT WHERE Account_ID = @new_account_id;
SELECT * FROM TRANSACTION WHERE Account_ID = @new_account_id;
SELECT * FROM BACKUP_LOGS 
WHERE Filepath COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', @new_customer_id, '%') 
ORDER BY Timestamp DESC LIMIT 1;

--! Example for issue a new card for account 105
SET @new_card_id = NULL;
CALL issue_new_card(105, 'Gold', @new_card_id);
SELECT @new_card_id AS New_Card_ID FROM DUAL;
SELECT * FROM CARD WHERE Card_ID = @new_card_id;
SELECT * FROM BACKUP_LOGS 
WHERE Filepath COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', @new_card_id, '%')

--! Example for apply for a loan for account 107
SET @new_loan_id = NULL;
SET @loan_status = NULL;
SELECT Credit_Score FROM ACCOUNT WHERE Account_ID = 107;
CALL apply_for_loan(107, 1000, 'Auto', 36, @new_loan_id, @loan_status);
SELECT @new_loan_id AS New_Loan_ID, @loan_status AS Loan_Status FROM DUAL;

--! Example for add a new branch
SET @new_branch_id = NULL;
CALL add_new_branch('Downtown Branch', '100 Main St, Banking City', @new_branch_id);
SELECT @new_branch_id AS New_Branch_ID;
SELECT * FROM BRANCH WHERE Branch_ID = @new_branch_id;
SELECT * FROM BACKUP_LOGS WHERE Filepath LIKE '%branch_creation%' ORDER BY Timestamp DESC LIMIT 1;

--! Example for add an AI advisor message
SET @advisor_id = NULL;
CALL add_ai_advisor_message(
    'Branch audit completed successfully. No issues found.',
    'Audit',
    @advisor_id
);
SELECT * FROM AI_ADVISOR WHERE Advisor_ID = @advisor_id;