-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
USE bank_management_system;

--! Add
-- Adding a new customer
INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
VALUES (8, 'John', 'Doe', 'Male', 'john.doe@example.com', '123 Main St', '555-1234', '123-45-6789', 750, '1985-06-15');

-- Adding an account for the customer
INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
VALUES (111, CURRENT_DATE(), 5000.00, 'Savings', 750, 8);

-- Adding a transaction
INSERT INTO TRANSACTION (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES (2001, 'Initial deposit', 'Deposit', NOW(), 5000.00, 111);

--! Update
-- Update customer's phone number
UPDATE CUSTOMER 
SET Phone = '555-5678' 
WHERE Customer_ID = 8;

-- Update account balance after a transaction
UPDATE ACCOUNT 
SET Balance = Balance + 1000.00 
WHERE Account_ID = 111;

-- Update transaction description
UPDATE TRANSACTION 
SET Description = 'Initial deposit - Welcome bonus' 
WHERE Transaction_ID = 1001;

--! Delete
-- Delete a transaction
DELETE FROM TRANSACTION 
WHERE Transaction_ID = 1001;

-- Delete a customer's account-- First delete the transactions associated with account 110
DELETE FROM TRANSACTION 
WHERE Account_ID = 110;

-- Then delete the account
DELETE FROM ACCOUNT 
WHERE Account_ID = 110;

-- Delete a customer (handling foreign key constraints properly)
-- First delete any transactions associated with customer's accounts
DELETE FROM TRANSACTION 
WHERE Account_ID IN (SELECT Account_ID FROM ACCOUNT WHERE Customer_ID = 7);

-- Delete any customer login records
DELETE FROM CUSTOMER_LOGIN
WHERE Customer_ID = 7;

-- Then delete the customer's accounts
DELETE FROM ACCOUNT 
WHERE Customer_ID = 7;

-- Finally delete the customer record
DELETE FROM CUSTOMER 
WHERE Customer_ID = 7;

--! Select
-- Basic select statements
SELECT * FROM CUSTOMER WHERE Credit_Score > 700;
SELECT Account_ID, Balance, Account_Type FROM ACCOUNT WHERE Customer_ID = 4;
SELECT * FROM TRANSACTION WHERE Transaction_Type = 'Deposit' AND Amount > 850;

-- Find customers with high credit scores
SELECT Customer_ID, F_Name, L_Name, Credit_Score 
FROM CUSTOMER 
WHERE Credit_Score > 700 
ORDER BY Credit_Score DESC;

-- Find accounts with low balances
SELECT a.Account_ID, a.Balance, c.F_Name, c.L_Name 
FROM ACCOUNT a
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
WHERE a.Balance < 5000;

-- Find recent transactions
SELECT t.Transaction_ID, t.Amount, t.Transaction_Type, t.Transaction_Time, c.F_Name, c.L_Name
FROM TRANSACTION t
JOIN ACCOUNT a ON t.Account_ID = a.Account_ID
JOIN CUSTOMER c ON a.Customer_ID = c.Customer_ID
WHERE t.Transaction_Time > DATE_SUB(NOW(), INTERVAL 7 DAY);