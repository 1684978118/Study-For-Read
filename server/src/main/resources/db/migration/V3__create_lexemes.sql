create table lexemes (
    id uuid not null,
    surface varchar(255) not null,
    normalized_surface varchar(255) not null,
    reading varchar(255),
    source_lang varchar(16) not null,
    target_lang varchar(16) not null,
    entry_type varchar(32) not null,
    part_of_speech varchar(64),
    definition text not null,
    short_definition varchar(500),
    example text,
    status varchar(32) not null,
    created_by_admin_id uuid,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint lexemes_pkey primary key (id),
    constraint lexemes_language_surface_entry_unique unique (
        source_lang,
        target_lang,
        normalized_surface,
        entry_type
    ),
    constraint lexemes_entry_type_check check (entry_type in ('word', 'phrase', 'idiom')),
    constraint lexemes_status_check check (status in ('active', 'candidate', 'rejected')),
    constraint lexemes_normalized_surface_check check (normalized_surface = lower(trim(normalized_surface)))
);

create index lexemes_normalized_surface_idx on lexemes (normalized_surface);
create index lexemes_status_idx on lexemes (status);
