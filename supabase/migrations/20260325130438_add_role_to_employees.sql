-- Migration to add details and role to employees table
ALTER TABLE employees ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'employee';
ALTER TABLE employees ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
