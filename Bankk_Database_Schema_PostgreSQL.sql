CREATE TABLE customers (
  customer_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name          TEXT NOT NULL,         -- Full legal name
  birth_date          DATE,
  national_id_number  TEXT,                  -- Can store encrypted/hashed
  residency_country   CHAR(2),                -- ISO 3166-1 alpha-2
  customer_type       VARCHAR(20),           -- e.g., Regular, Premium, SME
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE customer_contacts (
  contact_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id   UUID NOT NULL REFERENCES customers(customer_id),
  kind          TEXT NOT NULL CHECK (kind IN ('email','phone','mobile','other')),
  value         TEXT NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE customer_addresses (
  address_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id   UUID NOT NULL REFERENCES customers(customer_id),
  line1         TEXT NOT NULL,
  line2         TEXT,
  city          TEXT NOT NULL,
  state_region  TEXT,
  postal_code   TEXT,
  country       CHAR(2) NOT NULL,
  from_date     DATE,
  to_date       DATE
);

-- Sepparated Addresses and Contacts so you can store multiple per customer and track history
-- This is in compliance with KYC, Know your Customer regulations


CREATE TABLE products (
  product_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name  TEXT NOT NULL,            -- e.g. "Savings Account Plus"
  product_type  TEXT NOT NULL CHECK (
                   product_type IN ('Savings','Current','Fixed Deposit','Loan','Credit Card')
                 ),
  interest_rate NUMERIC(5,2),              -- e.g. 1.25 (%)
  min_balance   NUMERIC(15,2),             -- e.g. 500.00
  currency      CHAR(3) NOT NULL,          -- Follow ISO 4217 code (e.g. SGD, USD)
  description   TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);


CREATE TABLE accounts (
  account_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     UUID REFERENCES products(product_id),
  account_number TEXT UNIQUE NOT NULL,          -- Bank account number, "branch code (3 digits) - account number (8 digits)"
  iban           TEXT UNIQUE,                   -- Optional, for international use
  currency       CHAR(3) NOT NULL,               -- Follow ISO 4217 code (e.g., SGD, USD)
  status         TEXT NOT NULL CHECK (status IN ('enabled','disabled','closed','pending')),
  opened_at      TIMESTAMPTZ NOT NULL,
  closed_at      TIMESTAMPTZ,
  account_type   TEXT NOT NULL,                  -- Personal, Business
  sub_type       TEXT NOT NULL,                  -- CurrentAccount, Savings, etc.
  current_balance NUMERIC(15,2) DEFAULT 0.00     -- Running balance
);

CREATE TABLE account_parties (
  account_id   UUID NOT NULL REFERENCES accounts(account_id),
  customer_id  UUID NOT NULL REFERENCES customers(customer_id),
  role         TEXT NOT NULL CHECK (role IN ('PrimaryOwner','JointOwner','AuthorisedUser')),
  PRIMARY KEY (account_id, customer_id)
);

--

CREATE TABLE balances (
  balance_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id     UUID NOT NULL REFERENCES accounts(account_id),
  balance_type   TEXT NOT NULL CHECK (balance_type IN (
                     'ClosingAvailable', 'ClosingBooked',
                     'OpeningAvailable', 'InterimAvailable'
                   )),
  amount         NUMERIC(18,2) NOT NULL,
  currency       CHAR(3) NOT NULL,
  credit_debit   TEXT NOT NULL CHECK (credit_debit IN ('Credit','Debit')),
  reference_date DATE NOT NULL,  -- as of date
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE paynow_proxies ( -- When a PayNow payment is initiated, lookup proxy_value to find customer_id and account_id, then record to transactions
  proxy_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id  UUID NOT NULL REFERENCES customers(customer_id),
  account_id   UUID NOT NULL REFERENCES accounts(account_id),
  proxy_type   TEXT NOT NULL CHECK (proxy_type IN ('mobile','nric','uen')),
  proxy_value  TEXT NOT NULL UNIQUE,  -- E.g. '+6591234567' or 'S1234567A'
  is_active    BOOLEAN NOT NULL DEFAULT true, -- Allows disabling proxy without deleting
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
  transaction_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id             UUID NOT NULL REFERENCES accounts(account_id),
  booking_datetime       TIMESTAMPTZ NOT NULL, -- Date when the transaction is recorded in bank's system
  value_datetime         TIMESTAMPTZ, -- Date when interest or charges start to accrue for that transaction
  amount                 NUMERIC(18,2) NOT NULL,
  currency               CHAR(3) NOT NULL,
  credit_debit           TEXT NOT NULL CHECK (credit_debit IN ('Credit','Debit')),
  transaction_type       TEXT,  -- ATM Withdrawal, POS Purchase, etc.
  description            TEXT,
  merchant_name          TEXT,
  merchant_category_code CHAR(4), -- ISO 18245 MCC
  status                 TEXT NOT NULL CHECK (status IN ('Booked','Pending','Rejected')) DEFAULT 'Booked',
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
