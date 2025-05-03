# Characteristics of Our Database

## Security

- Critical for databases: Especially for banking systems that store sensitive customer information
- Implemented in: password hashes for users in CUSTOMER_LOGIN and EMPLOYEE_LOGIN tables
- Access control: Different user types (customers vs employees) with different permissions
- Audit trails: BACKUP_LOGS table tracks important system events

## Availability

- Uptime requirements: Databases need to be accessible when users need them
- Backup procedures: BACKUP_LOGS table suggests having a backup system in place
- Redundancy: Important for preventing data loss
- Scalability: Ability to handle increasing loads (our branch structure supports growth)

## User Friendliness

- Views: several views (customer_account_summary, transaction_history, etc.) that make complex data easier to understand
- Meaningful naming: tables and columns use clear, descriptive names
- Logical organization: Our schema follows a logical structure that models real-world banking entities
- Error messages: Our triggers provide helpful error messages (e.g., "Insufficient funds for withdrawal")

## Accuracy

- Data integrity: triggers enforce business rules (like preventing overdrafts)
- Consistency: Triggers like sync_credit_score ensure data is consistent across tables
- Validation: Constraints on data types and relationships
- Transaction support: SQL's transactional nature ensures operations are atomic
