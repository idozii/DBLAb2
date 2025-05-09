-- Active: 1745234709944@@127.0.0.1@3306@bank_management_system
DROP DATABASE IF EXISTS bank_management_system;
CREATE DATABASE bank_management_system;
USE bank_management_system;
CREATE TABLE CUSTOMER (
    Customer_ID INT PRIMARY KEY,
    F_Name VARCHAR(50),
    L_Name VARCHAR(50),
    Gender ENUM('Male', 'Female', 'Other'),
    Email VARCHAR(100) UNIQUE,
    Address TEXT,
    Phone VARCHAR(20),
    SSN VARCHAR(20) UNIQUE,
    Credit_Score INT,
    DOB DATE
);

CREATE TABLE CUSTOMER_LOGIN (
    Login_ID INT PRIMARY KEY,
    Username VARCHAR(50) UNIQUE,
    Password_Hash VARCHAR(255),
    Last_Login DATETIME,
    Status ENUM('Active', 'Inactive'),
    Customer_ID INT,
    FOREIGN KEY (Customer_ID) REFERENCES CUSTOMER(Customer_ID)
);

CREATE TABLE BACKUP_LOGS (
    Backup_ID INT PRIMARY KEY,
    Timestamp DATETIME,
    Filepath VARCHAR(255),
    Status ENUM('Success', 'Failed')
);

CREATE TABLE AI_ADVISOR (
    Advisor_ID INT PRIMARY KEY,
    Timestamp DATETIME,
    Content TEXT,
    Advisor_Type VARCHAR(50)
);

CREATE TABLE ACCOUNT (
    Account_ID INT PRIMARY KEY,
    Open_Date DATE,
    Balance DECIMAL(15,2),
    Account_Type VARCHAR(50),
    Credit_Score INT,
    Customer_ID INT,
    FOREIGN KEY (Customer_ID) REFERENCES CUSTOMER(Customer_ID)
);

CREATE TABLE CARD (
    Card_ID INT PRIMARY KEY,
    Card_Number VARCHAR(20) UNIQUE,
    Expiry_Date DATE,
    Card_Type VARCHAR(20),
    Card_Status ENUM('Active', 'Blocked'),
    Account_ID INT,
    FOREIGN KEY (Account_ID) REFERENCES ACCOUNT(Account_ID)
);

CREATE TABLE BRANCH (
    Branch_ID INT PRIMARY KEY,
    Branch_Name VARCHAR(100),
    Address TEXT
);

CREATE TABLE EMPLOYEE (
    Employee_ID INT PRIMARY KEY,
    F_Name VARCHAR(50),
    L_Name VARCHAR(50),
    Email VARCHAR(100),
    Address TEXT,
    Phone VARCHAR(20),
    Position VARCHAR(50),
    Salary DECIMAL(10,2),
    Start_Date DATE,
    Employment_Status ENUM('Active', 'Inactive'),
    Branch_ID INT,
    FOREIGN KEY (Branch_ID) REFERENCES BRANCH(Branch_ID)
);

CREATE TABLE EMPLOYEE_LOGIN (
    Login_ID INT PRIMARY KEY,
    Username VARCHAR(50) UNIQUE,
    Password_Hash VARCHAR(255),
    Last_Login DATETIME,
    Status ENUM('Active', 'Inactive'),
    Employee_ID INT,
    FOREIGN KEY (Employee_ID) REFERENCES EMPLOYEE(Employee_ID)
);

CREATE TABLE LOAN (
    Loan_ID INT PRIMARY KEY,
    Loan_Amount DECIMAL(15,2),
    Loan_Type VARCHAR(50),
    Start_Date DATE,
    End_Date DATE,
    Loan_Status ENUM('Approved', 'Pending', 'Rejected'),
    Account_ID INT,
    FOREIGN KEY (Account_ID) REFERENCES ACCOUNT(Account_ID)
);

CREATE TABLE TRANSACTION (
    Transaction_ID INT PRIMARY KEY,
    Description TEXT,
    Transaction_Type ENUM('Deposit', 'Withdrawal', 'Transfer'),
    Transaction_Time DATETIME,
    Amount DECIMAL(15,2),
    Account_ID INT,
    FOREIGN KEY (Account_ID) REFERENCES ACCOUNT(Account_ID)
);

-- Sample

INSERT INTO CUSTOMER (Customer_ID, F_Name, L_Name, Gender, Email, Address, Phone, SSN, Credit_Score, DOB)
VALUES 
    (4, 'Emily', 'Davis', 'Female', 'emily.davis@example.com', '567 Maple Dr, Banking City', '555-3456', '456-78-9012', 790, '1988-09-12'),
    (5, 'Michael', 'Wilson', 'Male', 'michael.wilson@example.com', '890 Cedar Lane, Banking City', '555-6789', '567-89-0123', 710, '1979-04-25'),
    (6, 'Jessica', 'Taylor', 'Female', 'jessica.taylor@example.com', '123 Birch St, Banking City', '555-7890', '678-90-1234', 840, '1992-07-18'),
    (7, 'David', 'Miller', 'Male', 'david.miller@example.com', '456 Walnut Ave, Banking City', '555-8901', '789-01-2345', 670, '1983-12-05');

INSERT INTO CUSTOMER_LOGIN (Login_ID, Username, Password_Hash, Last_Login, Status, Customer_ID)
VALUES 
    (4, 'edavis', 'hashed_password_7', '2023-05-02 14:20:00', 'Active', 4),
    (5, 'mwilson', 'hashed_password_8', '2023-05-02 10:45:00', 'Active', 5),
    (6, 'jtaylor', 'hashed_password_9', '2023-05-02 16:30:00', 'Active', 6),
    (7, 'dmiller', 'hashed_password_10', '2023-05-02 09:15:00', 'Active', 7);

INSERT INTO ACCOUNT (Account_ID, Open_Date, Balance, Account_Type, Credit_Score, Customer_ID)
VALUES 
    (105, '2022-04-10', 8500.00, 'Savings', 790, 4),
    (106, '2022-04-12', 3200.00, 'Checking', 790, 4),
    (107, '2022-03-15', 6700.00, 'Savings', 710, 5),
    (108, '2022-05-20', 15000.00, 'Premium Savings', 840, 6),
    (109, '2022-05-22', 4200.00, 'Checking', 840, 6),
    (110, '2022-02-28', 1800.00, 'Checking', 670, 7);

INSERT INTO `TRANSACTION` (Transaction_ID, Description, Transaction_Type, Transaction_Time, Amount, Account_ID)
VALUES
    (1001, 'Monthly savings deposit', 'Deposit', '2023-04-15 09:30:00', 500.00, 105),
    (1002, 'Grocery shopping', 'Withdrawal', '2023-04-16 14:45:00', 120.50, 106),
    (1003, 'Salary deposit', 'Deposit', '2023-04-25 08:00:00', 2500.00, 107),
    (1004, 'Investment transfer', 'Transfer', '2023-04-28 11:15:00', 1000.00, 108),
    (1005, 'Utility bill payment', 'Withdrawal', '2023-04-30 16:20:00', 85.75, 109),
    (1006, 'ATM withdrawal', 'Withdrawal', '2023-05-01 13:10:00', 200.00, 110);