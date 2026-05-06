create table users (
    id uuid not null,
    email varchar(255) not null,
    password_hash varchar(255) not null,
    display_name varchar(80),
    source_lang varchar(16) not null default 'ja',
    target_lang varchar(16) not null default 'zh-CN',
    status varchar(32) not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint users_pkey primary key (id),
    constraint users_email_unique unique (email),
    constraint users_email_lowercase_check check (email = lower(email)),
    constraint users_status_check check (status in ('active', 'disabled'))
);

create index users_status_idx on users (status);

create table refresh_tokens (
    id uuid not null,
    user_id uuid not null,
    token_hash char(64) not null,
    expires_at timestamp with time zone not null,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint refresh_tokens_pkey primary key (id),
    constraint refresh_tokens_user_id_fkey foreign key (user_id) references users (id) on delete cascade,
    constraint refresh_tokens_token_hash_unique unique (token_hash),
    constraint refresh_tokens_token_hash_length_check check (length(token_hash) = 64 and token_hash not like '% %'),
    constraint refresh_tokens_expires_after_created_check check (expires_at > created_at)
);

create index refresh_tokens_user_id_idx on refresh_tokens (user_id);
