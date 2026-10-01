-- PostgreSQL requires a committed enum addition before a later migration can use it.
alter type public.seller_document_kind
  add value if not exists 'medical_professional_registration';
