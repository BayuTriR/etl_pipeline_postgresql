-- ==============================================================================
-- PROSES TRANSFORM COLUMN CAMELCASE TO SNAKECASE
-- ==============================================================================

CREATE OR REPLACE FUNCTION silver.run_transformation_pipeline()
RETURNS void AS $$
DECLARE
    t_record RECORD;
    c_record RECORD;
    select_clause TEXT;
    new_col_name TEXT;
    query_str TEXT;
    target_table_name TEXT;
BEGIN
    -- Loop menyisir setiap TABEL yang ada di schema 'bronze'
    FOR t_record IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'bronze' 
          AND table_type = 'BASE TABLE'
    LOOP
        select_clause := '';

        -- Loop menyisir setiap KOLOM untuk tabel yang sedang aktif di-loop
        FOR c_record IN 
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'bronze' 
              AND table_name = t_record.table_name
            ORDER BY ordinal_position
        LOOP
            -- Proses konversi camelCase nama kolom ke snake_case
            new_col_name := regexp_replace(c_record.column_name, '([a-z0-9])([A-Z])', '\1_\2', 'g');
            new_col_name := regexp_replace(new_col_name, '([a-zA-Z])([0-9]+)', '\1_\2', 'g');
            new_col_name := lower(new_col_name);

            -- Susun bagian SELECT
            IF select_clause <> '' THEN
                select_clause := select_clause || ', ';
            END IF;
            select_clause := select_clause || format('%I AS %I', c_record.column_name, new_col_name);
        END LOOP;

        -- Nama tabel target
        IF t_record.table_name = 'raw_taxi_zones' THEN
            target_table_name := 'taxi_zones';
        ELSIF t_record.table_name = 'raw_taxi_trips' THEN
            target_table_name := 'temp_taxi_trips';
        ELSE
            target_table_name := t_record.table_name;
        END IF;

        -- Hapus tabel lama di silver jika ada
        EXECUTE format('DROP TABLE IF EXISTS silver.%I CASCADE', target_table_name);

        -- Eksekusi pembuatan tabel baru ke silver
        query_str := format('CREATE TABLE silver.%I AS SELECT %s FROM bronze.%I', target_table_name, select_clause, t_record.table_name);
        EXECUTE query_str;

        IF target_table_name = 'taxi_zones' THEN
            EXECUTE 'ALTER TABLE silver.taxi_zones ADD PRIMARY KEY (location_id)';
        END IF;

    END LOOP;

END;
$$ LANGUAGE plpgsql;

SELECT silver.run_transformation_pipeline();

DROP FUNCTION IF EXISTS silver.run_transformation_pipeline();

