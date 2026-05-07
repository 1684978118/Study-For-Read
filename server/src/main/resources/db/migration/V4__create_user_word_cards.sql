create table user_word_cards (
    id uuid not null,
    user_id uuid not null,
    lexeme_id uuid,
    card_type varchar(32) not null,
    private_surface varchar(500),
    private_definition text,
    private_context text,
    source_book_fingerprint char(64),
    source_book_title varchar(255),
    review_status varchar(32) not null,
    review_count integer not null,
    next_review_at timestamp with time zone,
    last_reviewed_at timestamp with time zone,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint user_word_cards_pkey primary key (id),
    constraint user_word_cards_user_id_fkey foreign key (user_id) references users (id) on delete cascade,
    constraint user_word_cards_lexeme_id_fkey foreign key (lexeme_id) references lexemes (id) on delete restrict,
    constraint user_word_cards_card_type_check check (card_type in ('lexeme', 'private_sentence')),
    constraint user_word_cards_review_status_check check (review_status in ('new', 'learning', 'known')),
    constraint user_word_cards_review_count_check check (review_count >= 0),
    constraint user_word_cards_lexeme_card_lexeme_id_check check (
        card_type <> 'lexeme' or lexeme_id is not null
    ),
    constraint user_word_cards_private_sentence_required_fields_check check (
        card_type <> 'private_sentence' or (private_surface is not null and private_definition is not null)
    ),
    constraint user_word_cards_source_book_fingerprint_check check (
        source_book_fingerprint is null
        or regexp_like(source_book_fingerprint, '^[0-9a-f]{64}$')
    )
);

create index user_word_cards_user_id_next_review_at_idx on user_word_cards (user_id, next_review_at);
create index user_word_cards_user_id_review_status_idx on user_word_cards (user_id, review_status);
create unique index user_word_cards_user_id_lexeme_id_unique
    on user_word_cards (user_id, lexeme_id);
