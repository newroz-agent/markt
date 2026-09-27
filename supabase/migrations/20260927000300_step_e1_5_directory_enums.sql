-- Step E1.5: new directory values. PostgreSQL requires committed enum additions
-- before the next migration can reference them.
alter type public.directory_business_type add value if not exists 'fast_food';

alter type public.directory_cuisine add value if not exists 'lebanese';
alter type public.directory_cuisine add value if not exists 'iraqi';
alter type public.directory_cuisine add value if not exists 'middle_eastern';
alter type public.directory_cuisine add value if not exists 'kebab';
alter type public.directory_cuisine add value if not exists 'falafel';
