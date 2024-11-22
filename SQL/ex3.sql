-- INSERT STATEMENTS

-- Create a new savings account for user with id `00001488-d55e-43c9-94a9-5c4b1b7ea2b0`
INSERT INTO wob.account(client_id, status, branch_id, account_type_id)
VALUES (
    '00001488-d55e-43c9-94a9-5c4b1b7ea2b0',
    'active',
    (SELECT branch_id FROM wob.branch LIMIT 1),
    (SELECT account_type_id FROM wob.account_type WHERE name = 'Savings')
)
RETURNING account_id;

-- Create a new transaction for the first user account with user id `0716ba97-1e28-49d2-9582-c99ecbac4c63` for $100
INSERT INTO wob.transaction(amount, datetime, status, account_id, merchant_name)
VALUES (
    100.00::money,
    current_timestamp(3),
    'paid',
    (SELECT account_id FROM wob.account WHERE client_id = '0716ba97-1e28-49d2-9582-c99ecbac4c63' LIMIT 1),
    'abcde'
)
RETURNING transaction_id;

-- Create a new address, and use the `address_id` to create a new user
WITH new_address AS (
    INSERT INTO wob.address(street_number, street_name, city, province, country, postal_code)
    VALUES (1151, 'Richmond Street', 'London', 'Ontario', 'Canada', 'N6A3K7')
    RETURNING address_id
)
INSERT INTO wob."user"(name, phone_number, email, date_of_birth, password, address_id)
VALUES (
    'John Doe',
    '+1 (647) 373-0304',
    'john.doe.1234@gmail.com',
    '2001-09-28',
    '66f23a50a26a03ee8dd01cf5449d408b4137ef3037d55d819ab28d1c9d902983',
    (SELECT address_id FROM new_address)
)
RETURNING user_id;