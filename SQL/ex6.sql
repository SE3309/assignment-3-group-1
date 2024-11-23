-- UPDATE STATEMENTS
DELETE FROM wob.transaction
WHERE transaction_id IN (
    SELECT t.transaction_id
    FROM wob.transaction t
    JOIN wob.account a ON t.account_id = a.account_id
    WHERE t.amount < 1000.00::money
    ORDER BY t.datetime ASC
    LIMIT 10 
);

-- Update pending loan applications, change their status and interest_id, and insert as new loans
WITH updated_applications AS (
    -- Update loan applications that are pending
    UPDATE wob.loan_application
    SET status = 'approved',
        interest_id = (SELECT interest_id FROM wob.interest ORDER BY random() LIMIT 1) -- Assign a new random interest rate
    WHERE status = 'pending'
    RETURNING loan_application_id, amount, client_id, interest_id -- Return updated applications
),
new_loans AS (
    -- Insert updated loan applications as new loans
    INSERT INTO wob.loan (loan_id, client_id, principal, interest_accumulated, term_months, monthly_payment_amount, status, interest_id)
    SELECT 
        gen_random_uuid(), -- Generate a new loan ID
        ua.client_id,
        ua.amount,
        (ua.amount::numeric * (SELECT interest_rate FROM wob.interest WHERE interest_id = ua.interest_id))::money AS interest_accumulated, -- Calculate new interest
        CASE 
            WHEN random() < 0.25 THEN 6
            WHEN random() < 0.50 THEN 12
            WHEN random() < 0.75 THEN 24
            ELSE 36
        END AS term_months, -- Random loan term
        ((ua.amount::numeric + (ua.amount::numeric * (SELECT interest_rate FROM wob.interest WHERE interest_id = ua.interest_id))) / 
         CASE 
             WHEN random() < 0.25 THEN 6
             WHEN random() < 0.50 THEN 12
             WHEN random() < 0.75 THEN 24
             ELSE 36
         END)::money AS monthly_payment_amount, -- Calculate monthly payment
        'active', -- Set loan status to active
        ua.interest_id
    FROM updated_applications ua
    RETURNING loan_id -- Return newly inserted loans
)
-- Retrieve results to confirm
SELECT * FROM new_loans;

WITH high_transaction_accounts AS (
    -- Identify accounts with more than 100 transactions
    SELECT 
        a.client_id,
        a.account_id,
        COUNT(t.transaction_id) AS transaction_count
    FROM wob.transaction t
    JOIN wob.account a ON t.account_id = a.account_id -- Link transactions to accounts
    WHERE t.status = 'completed' -- Only consider completed transactions
    GROUP BY a.client_id, a.account_id
    HAVING COUNT(t.transaction_id) > 100 -- Adjusted threshold for high transaction accounts
),
updated_accounts AS (
    -- Update account status for high-transaction accounts
    UPDATE wob.account
    SET status = 'high_transactions'
    FROM high_transaction_accounts hta
    WHERE wob.account.account_id = hta.account_id
      AND wob.account.status != 'high_transactions' -- Avoid redundant updates
    RETURNING hta.client_id
)
-- Insert notifications for affected clients
INSERT INTO wob.notification (notification_id, message, datetime, client_id)
SELECT 
    gen_random_uuid(), -- Unique notification ID
    'Your account has been flagged for high transaction volume exceeding 100 transactions.',
    NOW(),
    ua.client_id
FROM updated_accounts ua;