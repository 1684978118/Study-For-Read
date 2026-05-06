create table user_books (
    id uuid not null,
    user_id uuid not null,
    book_fingerprint char(64) not null,
    title varchar(255) not null,
    author varchar(255),
    file_type varchar(16) not null,
    source_lang varchar(16) not null,
    target_lang varchar(16) not null,
    chapter_count integer not null,
    current_chapter_index integer not null,
    current_paragraph_index integer not null,
    current_char_offset integer not null,
    last_read_at timestamp with time zone,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint user_books_pkey primary key (id),
    constraint user_books_user_id_fkey foreign key (user_id) references users (id) on delete cascade,
    constraint user_books_user_book_fingerprint_unique unique (user_id, book_fingerprint),
    constraint user_books_book_fingerprint_length_check check (
        length(book_fingerprint) = 64 and book_fingerprint = lower(book_fingerprint)
    ),
    constraint user_books_file_type_check check (file_type in ('txt', 'epub')),
    constraint user_books_chapter_count_check check (chapter_count >= 1),
    constraint user_books_current_chapter_index_check check (current_chapter_index >= 0),
    constraint user_books_current_paragraph_index_check check (current_paragraph_index >= 0),
    constraint user_books_current_char_offset_check check (current_char_offset >= 0)
);

create index user_books_user_id_last_read_at_idx on user_books (user_id, last_read_at);
