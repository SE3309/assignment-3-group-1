-- SELECT STATEMENTS

-- Get user with all their accounts and all their cards
SELECT "user".name, "user".phone_number, "user".email, "user".date_of_birth,
       client.student_number, client.status AS client_status,
       account.balance, account.status AS account_status,
       account_type.name AS account_type,
       bank_card.expiry_date AS card_expiry_date, bank_card.card_number, bank_card.status AS card_status, bank_card.daily_limit,
       card_type.name AS card_type,
       interest.interest_rate, interest.interest_type
FROM wob."user"
JOIN wob.client ON wob.client.user_id = wob."user".user_id
JOIN wob.account ON wob.account.client_id = wob.client.client_id
JOIN wob.account_type ON wob.account_type.account_type_id = wob.account.account_type_id
LEFT JOIN wob.bank_card ON wob.bank_card.account_id = wob.account.account_id
LEFT JOIN wob.card_type ON wob.card_type.card_type_id = wob.bank_card.card_type_id
LEFT JOIN wob.interest ON wob.interest.interest_id = wob.card_type.interest_id
WHERE "user".name = 'Annamaria Hercule Fredenburg';

-- Get staff member, with their role, branch and the branch's address
SELECT "user".name, "user".phone_number, "user".email, "user".date_of_birth,
       staff.status AS staff_status,
       staff_role.name AS staff_role_name, staff_role.base_salary,
       address.street_number AS branch_street_number, address.street_name AS branch_street_name, address.city AS branch_city, address.province AS branch_province, address.country AS branch_country, address.postal_code AS branch_postal_code
FROM wob."user"
JOIN wob.staff ON wob.staff.user_id = wob."user".user_id
JOIN wob.staff_role ON wob.staff_role.staff_role_id = wob.staff.staff_role_id
JOIN wob.branch ON wob.branch.branch_id = wob.staff.branch_id
JOIN wob.address ON wob.address.address_id = wob.branch.address_id
WHERE "user".name = 'Candice Dolf';

-- Get all users with their total balance, ordered by total balance from highest to lowest
SELECT "user".user_id, "user".name, "user".phone_number, "user".email,
       client.status AS client_status,
       SUM(account.balance) AS total_balance
FROM wob."user"
JOIN wob.client ON wob.client.user_id = wob."user".user_id
JOIN wob.account ON wob.account.client_id = wob.client.client_id
GROUP BY wob."user".user_id, client.status
ORDER BY total_balance DESC;

-- Get the average bank account balance for each account type
SELECT AVG(account.balance::numeric)::money AS average_bank_account_balance,
       account_type.name AS account_type
FROM wob."user"
JOIN wob.client ON wob.client.user_id = wob."user".user_id
JOIN wob.account ON wob.account.client_id = wob.client.client_id
JOIN wob.account_type ON wob.account_type.account_type_id = wob.account.account_type_id
GROUP BY account_type;

-- Get the total amount of money spent on transactions for each month
SELECT to_char(date_trunc('month', datetime), 'YYYY-MM') AS year_month, SUM(amount)
FROM wob.transaction
WHERE status <> 'failed'
GROUP BY year_month
ORDER BY year_month DESC;

-- Get the total account balance for each forward sortation area
SELECT SUBSTRING(postal_code, 0, 4) AS forward_sortation_area,
       SUM(balance) AS total_account_balance
FROM wob.address
JOIN wob."user" ON wob.address.address_id = wob."user".address_id
JOIN wob.client ON wob."user".user_id = wob.client.user_id
JOIN wob.account ON wob.client.client_id = wob.account.client_id
GROUP BY forward_sortation_area
ORDER BY total_account_balance DESC;