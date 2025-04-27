-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
USE bank_management_system;

-- ==================== TRIGGERS ====================

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

-- ==================== VIEWS ====================

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