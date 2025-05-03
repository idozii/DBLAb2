-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
USE bank_management_system;

DROP VIEW IF EXISTS branch_employee_summary;
DROP VIEW IF EXISTS active_loans_summary;
DROP VIEW IF EXISTS transaction_history;
DROP VIEW IF EXISTS customer_account_summary;

DROP TRIGGER IF EXISTS sync_credit_score;
DROP TRIGGER IF EXISTS log_customer_login_status;
DROP TRIGGER IF EXISTS prevent_overdraft;
DROP TRIGGER IF EXISTS update_account_balance;

DELETE FROM TRANSACTION;
DELETE FROM LOAN;
DELETE FROM CARD;
DELETE FROM ACCOUNT;
DELETE FROM EMPLOYEE_LOGIN;
DELETE FROM EMPLOYEE;
DELETE FROM BRANCH;
DELETE FROM CUSTOMER_LOGIN;
DELETE FROM CUSTOMER;
DELETE FROM BACKUP_LOGS;
DELETE FROM AI_ADVISOR;

-- Insert branch data
INSERT INTO BRANCH (Branch_ID, Branch_Name, Address)
VALUES 
    (1, 'Main Branch', '100 Finance St, Banking City'),
    (2, 'Downtown Branch', '200 Central Ave, Banking City');

-- Insert employee data (Use different IDs than Account_ID to avoid conflicts)
INSERT INTO EMPLOYEE (Employee_ID, F_Name, L_Name, Email, Address, Phone, Position, Salary, Start_Date, Employment_Status, Branch_ID)
VALUES 
    (201, 'Jane', 'Smith', 'jane.smith@bank.com', '10 Employee St', '555-1000', 'Manager', 75000.00, '2015-03-15', 'Active', 1),
    (202, 'Mike', 'Johnson', 'mike.johnson@bank.com', '20 Staff Ave', '555-1001', 'Teller', 45000.00, '2018-06-10', 'Active', 1),
    (203, 'Sarah', 'Williams', 'sarah.williams@bank.com', '30 Worker Rd', '555-1002', 'Loan Officer', 60000.00, '2017-09-05', 'Active', 2);

-- Insert employee login data
INSERT INTO EMPLOYEE_LOGIN (Login_ID, Username, Password_Hash, Last_Login, Status, Employee_ID)
VALUES 
    (201, 'jsmith', 'hashed_password_1', '2023-05-01 08:30:00', 'Active', 201),
    (202, 'mjohnson', 'hashed_password_2', '2023-05-01 09:15:00', 'Active', 202),
    (203, 'swilliams', 'hashed_password_3', '2023-05-01 08:45:00', 'Active', 203);

-- Insert customer data (Start with ID 1 as schema.sql starts with ID 4)
INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
VALUES 
    (1, 'John', 'Doe', 'Male', 'john.doe@example.com', '123 Main St', '555-1234', '123-45-6789', 750, '1985-06-15'),
    (2, 'Mary', 'Johnson', 'Female', 'mary.johnson@example.com', '456 Oak Ave', '555-5678', '234-56-7890', 820, '1990-03-22'),
    (3, 'Robert', 'Brown', 'Male', 'robert.brown@example.com', '789 Pine Rd', '555-9012', '345-67-8901', 680, '1975-11-08');

-- Insert customer login data
INSERT INTO CUSTOMER_LOGIN (Login_ID, Username, Password_Hash, Last_Login, Status, Customer_ID)
VALUES 
    (1, 'jdoe', 'hashed_password_4', '2023-05-01 10:00:00', 'Active', 1),
    (2, 'mjohnson', 'hashed_password_5', '2023-05-01 11:30:00', 'Active', 2),
    (3, 'rbrown', 'hashed_password_6', '2023-05-01 09:45:00', 'Active', 3);

-- Insert account data (Use IDs 1-3 since schema.sql uses IDs 105-110)
INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
VALUES 
    (1, '2022-01-15', 5000.00, 'Savings', 750, 1),
    (2, '2022-02-20', 3500.00, 'Checking', 750, 1),
    (3, '2022-01-10', 12000.00, 'Savings', 820, 2),
    (4, '2022-03-05', 2500.00, 'Checking', 680, 3);

-- Insert card data
INSERT INTO CARD (Card_ID, Card_Number, Expiry_Date, Card_Type, Card_Status, Account_ID)
VALUES 
    (1, '4111111111111111', '2025-12-31', 'Debit', 'Active', 2),
    (2, '5111111111111111', '2025-10-31', 'Credit', 'Active', 3),
    (3, '6111111111111111', '2026-05-31', 'Debit', 'Active', 4);

-- Insert loan data
INSERT INTO LOAN (Loan_ID, Loan_Amount, Loan_Type, Start_Date, End_Date, Loan_Status, Account_ID)
VALUES 
    (1, 25000.00, 'Personal', '2022-03-10', '2025-03-10', 'Approved', 1),
    (2, 150000.00, 'Mortgage', '2022-04-15', '2042-04-15', 'Approved', 3),
    (3, 15000.00, 'Auto', '2022-05-20', '2025-05-20', 'Pending', 4);

-- Insert some sample AI advisor data
INSERT INTO AI_ADVISOR (Advisor_ID, Timestamp, Content, Advisor_Type)
VALUES 
    (1, '2023-05-01 12:30:00', 'Based on your spending habits, we recommend setting up a recurring savings transfer.', 'Financial Planning'),
    (2, '2023-05-01 12:35:00', 'Your credit score could be improved by reducing credit card balances.', 'Credit Score');

-- Insert backup logs
INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
VALUES 
    (1, '2023-05-01 00:00:00', '/backups/daily/2023-05-01.bak', 'Success'),
    (2, '2023-05-02 00:00:00', '/backups/daily/2023-05-02.bak', 'Success');

-- Step 3: Set up triggers (from advanced.sql)

-- Trigger 1: Automatically update account balance when a transaction is made
DELIMITER //
CREATE TRIGGER update_account_balance
AFTER INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
    IF NEW.Transaction_Type = 'Deposit' THEN
        UPDATE ACCOUNT SET Balance = Balance + NEW.Amount 
        WHERE Account_ID = NEW.Account_ID;
    ELSEIF NEW.Transaction_Type = 'Withdrawal' THEN
        UPDATE ACCOUNT SET Balance = Balance - NEW.Amount 
        WHERE Account_ID = NEW.Account_ID;
    END IF;
END //
DELIMITER ;

-- Trigger 2: Prevent withdrawals that would result in negative balance
DELIMITER //
CREATE TRIGGER prevent_overdraft
BEFORE INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);
    
    IF NEW.Transaction_Type = 'Withdrawal' THEN
        SELECT Balance INTO current_balance FROM ACCOUNT WHERE Account_ID = NEW.Account_ID;
        
        IF (current_balance < NEW.Amount) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Insufficient funds for withdrawal';
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger 3: Log when customer login status changes
DELIMITER //
CREATE TRIGGER log_customer_login_status
AFTER UPDATE ON CUSTOMER_LOGIN
FOR EACH ROW
BEGIN
    IF NEW.Status != OLD.Status THEN
        INSERT INTO BACKUP_LOGS (Backup_ID, Timestamp, Filepath, Status)
        VALUES (NULL, NOW(), CONCAT('Customer login status change: ', NEW.Username), 'Success');
    END IF;
END //
DELIMITER ;

-- Trigger 4: Update credit score in ACCOUNT when it changes in CUSTOMER
DELIMITER //
CREATE TRIGGER sync_credit_score
AFTER UPDATE ON CUSTOMER
FOR EACH ROW
BEGIN
    IF NEW.Credit_Score != OLD.Credit_Score THEN
        UPDATE ACCOUNT 
        SET Credit_Score = NEW.Credit_Score
        WHERE Customer_ID = NEW.Customer_ID;
    END IF;
END //
DELIMITER ;

-- Step 4: Create views (from advanced.sql)

-- View 1: Customer Account Summary
CREATE VIEW customer_account_summary AS
SELECT 
    c.Customer_ID,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name,
    c.Email,
    c.Phone,
    COUNT(a.Account_ID) AS Total_Accounts,
    SUM(a.Balance) AS Total_Balance,
    MAX(a.Open_Date) AS Latest_Account_Open_Date,
    c.Credit_Score
FROM CUSTOMER c
LEFT JOIN ACCOUNT a ON c.Customer_ID = a.Customer_ID
GROUP BY c.Customer_ID, Customer_Name, c.Email, c.Phone, c.Credit_Score;

-- View 2: Transaction History
CREATE VIEW transaction_history AS
SELECT 
    t.Transaction_ID,
    t.Transaction_Time,
    t.Transaction_Type,
    t.Amount,
    t.Description,
    a.Account_ID,
    a.Account_Type,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name
FROM TRANSACTION t
JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
ORDER BY t.Transaction_Time DESC;

-- View 3: Active Loans Summary
CREATE VIEW active_loans_summary AS
SELECT 
    l.Loan_ID,
    l.Loan_Amount,
    l.Loan_Type,
    l.Start_Date,
    l.End_Date,
    l.Loan_Status,
    a.Account_ID,
    a.Account_Type,
    CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name,
    c.Credit_Score
FROM LOAN l
JOIN ACCOUNT a ON l.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
WHERE l.Loan_Status = 'Approved';

-- View 4: Branch Employee Summary
CREATE VIEW branch_employee_summary AS
SELECT 
    b.Branch_ID,
    b.Branch_Name,
    b.Address AS Branch_Address,
    COUNT(e.Employee_ID) AS Total_Employees,
    AVG(e.Salary) AS Average_Salary,
    SUM(CASE WHEN e.Employment_Status = 'Active' THEN 1 ELSE 0 END) AS Active_Employees,
    SUM(CASE WHEN e.Employment_Status = 'Inactive' THEN 1 ELSE 0 END) AS Inactive_Employees
FROM BRANCH b
LEFT JOIN EMPLOYEE e ON b.Branch_ID = e.Branch_ID
GROUP BY b.Branch_ID, b.Branch_Name, b.Address;

-- Step 5: Test basic operations

-- Test basic operations (from basic.sql)
-- Test 1: Test transaction insertion and balance update trigger
SELECT 'TEST 1: Testing transaction insertion and balance update trigger' AS 'Test Description';
SELECT Account_ID, Balance FROM ACCOUNT WHERE Account_ID = 1;
INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES (1, 'Test deposit', 'Deposit', NOW(), 1000.00, 1);
SELECT Account_ID, Balance FROM ACCOUNT WHERE Account_ID = 1;

-- Test 2: Test overdraft prevention trigger
SELECT 'TEST 2: Testing overdraft prevention trigger' AS 'Test Description';
SELECT Account_ID, Balance FROM ACCOUNT WHERE Account_ID = 4;
-- This should cause an error due to insufficient funds
-- Uncomment to test the error: INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID) VALUES (2, 'Test withdrawal with insufficient funds', 'Withdrawal', NOW(), 9999.00, 4);

-- Insert a valid withdrawal
INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES (2, 'Test withdrawal', 'Withdrawal', NOW(), 500.00, 4);
SELECT Account_ID, Balance FROM ACCOUNT WHERE Account_ID = 4;

-- Test 3: Test credit score sync trigger
SELECT 'TEST 3: Testing credit score sync trigger' AS 'Test Description';
SELECT Customer_ID, Credit_Score FROM CUSTOMER WHERE Customer_ID = 1;
SELECT Account_ID, Credit_Score FROM ACCOUNT WHERE Customer_ID = 1;
UPDATE CUSTOMER SET Credit_Score = 780 WHERE Customer_ID = 1;
SELECT Customer_ID, Credit_Score FROM CUSTOMER WHERE Customer_ID = 1;
SELECT Account_ID, Credit_Score FROM ACCOUNT WHERE Customer_ID = 1;

-- Test 4: Test customer login status change trigger
SELECT 'TEST 4: Testing customer login status change trigger' AS 'Test Description';
SELECT COUNT(*) AS 'Initial backup log count' FROM BACKUP_LOGS;
UPDATE CUSTOMER_LOGIN SET Status = 'Inactive' WHERE Login_ID = 1;
SELECT COUNT(*) AS 'New backup log count' FROM BACKUP_LOGS;
SELECT * FROM BACKUP_LOGS ORDER BY Backup_ID DESC LIMIT 1;

-- Step 6: Test views

-- Test 5: Test customer account summary view
SELECT 'TEST 5: Testing customer account summary view' AS 'Test Description';
SELECT * FROM customer_account_summary;

-- Test 6: Test transaction history view
SELECT 'TEST 6: Testing transaction history view' AS 'Test Description';
SELECT * FROM transaction_history;

-- Test 7: Test active loans summary view
SELECT 'TEST 7: Testing active loans summary view' AS 'Test Description';
SELECT * FROM active_loans_summary;

-- Test 8: Test branch employee summary view
SELECT 'TEST 8: Testing branch employee summary view' AS 'Test Description';
SELECT * FROM branch_employee_summary;

-- Step 7: Test Additional Functionality

-- Test 9: Test joins and filters
SELECT 'TEST 9: Testing joins and filters' AS 'Test Description';
-- Find all accounts with their customer information and ordered by balance
SELECT a.Account_ID, a.Account_Type, a.Balance, CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name, c.Email
FROM ACCOUNT a
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
ORDER BY a.Balance DESC;

-- Find all loans with customer information
SELECT l.Loan_ID, l.Loan_Type, l.Loan_Amount, l.Loan_Status, 
       CONCAT(c.F_Name, ' ', c.L_Name) AS Customer_Name, c.Credit_Score
FROM LOAN l
JOIN ACCOUNT a ON l.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
ORDER BY l.Loan_Amount DESC;

-- Test 10: Test complex queries with aggregation
SELECT 'TEST 10: Testing complex queries with aggregation' AS 'Test Description';
-- Calculate average balance by account type
SELECT Account_Type, AVG(Balance) AS Average_Balance, COUNT(*) AS Number_Of_Accounts
FROM ACCOUNT
GROUP BY Account_Type;

-- Calculate total approved loan amount by loan type
SELECT Loan_Type, SUM(Loan_Amount) AS Total_Loan_Amount, COUNT(*) AS Number_Of_Loans
FROM LOAN
WHERE Loan_Status = 'Approved'
GROUP BY Loan_Type;