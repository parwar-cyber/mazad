-- Cross-locale search vector for listings.  Per i18n-rtl skill §Search and
-- architecture.md §4 (Postgres tsvector + pg_trgm + unaccent).

-- Add the generated tsvector column.  Phase 2 will use this for search RPCs.
alter table listings add column search_vector tsvector
  generated always as (
    setweight(
      to_tsvector('simple', unaccent(
        coalesce(title_translations->>'en','') || ' ' ||
        coalesce(title_translations->>'ar','') || ' ' ||
        coalesce(title_translations->>'ku','') || ' ' ||
        coalesce(title_translations->>'tr','')
      )), 'A')
    ||
    setweight(
      to_tsvector('simple', unaccent(
        coalesce(description_translations->>'en','') || ' ' ||
        coalesce(description_translations->>'ar','') || ' ' ||
        coalesce(description_translations->>'ku','') || ' ' ||
        coalesce(description_translations->>'tr','')
      )), 'B')
  ) stored;

create index listings_search_idx on listings using gin(search_vector);

-- pg_trgm index on the EN title for fuzzy "did you mean" suggestions.
create index listings_title_en_trgm_idx
  on listings using gin ((coalesce(title_translations->>'en','')) gin_trgm_ops);
