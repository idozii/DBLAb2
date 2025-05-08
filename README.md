# Bank Management System Database

Our bank management system database provides a comprehensive solution for managing banking operations with an emphasis on security, availability, user-friendliness, and accuracy.

## Security

- **Critical for banking systems**: Protects sensitive customer information including personal details and financial data
- **Password protection**: Secure password hashes stored in CUSTOMER_LOGIN and EMPLOYEE_LOGIN tables
- **Role-based access control**: Different permissions for customers and employees
- **Audit logging**: BACKUP_LOGS table records system events for security monitoring

## Availability

- **High uptime guarantees**: Database designed for continuous operation
- **Backup management**: Automated backup system tracked through BACKUP_LOGS
- **Data redundancy**: Structure prevents single points of failure
- **Scalable architecture**: Branch structure supports organizational growth

## User Friendliness

- **Intuitive data views**: Specialized views like customer_account_summary and transaction_history simplify data access
- **Clear naming conventions**: Self-documenting table and column names
- **Domain-appropriate structure**: Schema mirrors real-world banking relationships
- **Informative feedback**: Helpful error messages (e.g., "Insufficient funds for withdrawal")

## Accuracy

- **Data integrity controls**: Triggers enforce business rules like overdraft prevention
- **Consistency mechanisms**: Automatic data synchronization (e.g., sync_credit_score trigger)
- **Validation constraints**: Data types and relationships are strictly enforced
- **ACID transaction support**: All operations maintain database consistency

## Key Database Objects

- **11 Tables**: Including CUSTOMER, ACCOUNT, TRANSACTION, LOAN, and EMPLOYEE
- **4 Triggers**: For balance updates, overdraft prevention, login tracking, and credit score synchronization
- **4 Views**: Providing insights into customers, transactions, loans, and branch operations
- **Multiple relationships**: Foreign key constraints maintain referential integrity
