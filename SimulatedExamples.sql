-- Creation of a new product in products table
INSERT INTO products (
  product_name,
  product_type,
  interest_rate,
  min_balance,
  currency,
  description
) VALUES (
  'POSBkids Savings Account',
  'Savings',
  0.05,             -- Kids accounts usually have very low interest, say 0.05%
  0.00,             -- No minimum balance requirement
  'SGD',
  'A savings account designed for children under 16, with no minimum balance and low interest. Helps inculcate the habit of saving early.'
);