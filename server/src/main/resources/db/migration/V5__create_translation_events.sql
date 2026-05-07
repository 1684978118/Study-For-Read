create table translation_events (
    id uuid not null,
    user_id uuid not null,
    request_type varchar(32) not null,
    source_lang varchar(16) not null,
    target_lang varchar(16) not null,
    provider varchar(64),
    source_text_hash char(64) not null,
    source_text_length integer not null,
    success boolean not null,
    error_code varchar(64),
    created_at timestamp with time zone not null default now(),
    constraint translation_events_pkey primary key (id),
    constraint translation_events_user_id_fkey foreign key (user_id) references users (id) on delete restrict,
    constraint translation_events_request_type_check check (
        request_type in ('word_lookup', 'paragraph_translation', 'annotation')
    ),
    constraint translation_events_source_text_hash_check check (
        regexp_like(source_text_hash, '^[0-9a-f]{64}$')
    ),
    constraint translation_events_source_text_length_check check (source_text_length > 0)
);

create index translation_events_user_id_created_at_idx on translation_events (user_id, created_at);
create index translation_events_request_type_created_at_idx on translation_events (request_type, created_at);
