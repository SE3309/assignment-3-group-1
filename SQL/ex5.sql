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

---Retrieve the total balance for each client who has at least one active account and has made at least one transaction with an amount greater than $500
SELECT 
    c.client_id,
    c.user_id,
    SUM(a.balance)::money AS total_balance, -- Total balance for active accounts
    COUNT(t.transaction_id) AS high_value_transactions -- Count of transactions > $500
FROM wob.client c
JOIN wob.account a ON c.client_id = a.client_id
LEFT JOIN wob.transaction t ON a.account_id = t.account_id
WHERE a.status = 'active'
  AND EXISTS (
      SELECT 1 
      FROM wob.transaction sub_t
      WHERE sub_t.account_id = a.account_id 
        AND sub_t.amount::numeric > 500.00 -- At least one transaction > $500
  )
GROUP BY c.client_id, c.user_id
ORDER BY total_balance DESC; -- Order by total balance

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

-- Get the count of users with the same family name
SELECT COUNT(*) AS family_name_count, arr[array_length(arr, 1)] AS family_name
FROM (
    SELECT string_to_array(name, ' ') AS arr
    FROM wob."user"
) AS sub
GROUP BY family_name
ORDER BY family_name_count DESC
LIMIT 12;