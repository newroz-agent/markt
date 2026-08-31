-- Unified listing model: extend product lifecycle with moderation states.
-- Scope decision (2026-08-30): business stores AND private individuals submit
-- listings through ONE flow; every listing starts pending_review and becomes
-- public only after manual admin approval.

alter type public.product_status add value if not exists 'pending_review' before 'sold';
alter type public.product_status add value if not exists 'rejected' before 'sold';
