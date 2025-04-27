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

