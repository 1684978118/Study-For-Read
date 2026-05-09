create table admin_users (
    id uuid not null,
    username varchar(80) not null,
    credential_hash varchar(255) not null,
    role varchar(32) not null,
    status varchar(32) not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint admin_users_pkey primary key (id),
    constraint admin_users_username_unique unique (username),
    constraint admin_users_role_check check (role in ('admin', 'operator')),
    constraint admin_users_status_check check (status in ('active', 'disabled'))
);

create index admin_users_status_idx on admin_users (status);

create table admin_audit_logs (
    id uuid not null,
    admin_user_id uuid not null,
    action varchar(128) not null,
    target_type varchar(64) not null,
    target_id uuid,
    details_json jsonb,
    ip_address varchar(64),
    created_at timestamp with time zone not null default now(),
    constraint admin_audit_logs_pkey primary key (id),
    constraint admin_audit_logs_admin_user_id_fkey
        foreign key (admin_user_id) references admin_users (id) on delete restrict
);

create index admin_audit_logs_admin_user_id_created_at_idx
    on admin_audit_logs (admin_user_id, created_at);
create index admin_audit_logs_target_type_target_id_idx
    on admin_audit_logs (target_type, target_id);

alter table lexemes
    add constraint lexemes_created_by_admin_id_fkey
    foreign key (created_by_admin_id) references admin_users (id) on delete set null;
