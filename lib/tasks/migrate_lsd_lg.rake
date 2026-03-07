# frozen_string_literal: true
#
# Migration task: lsd_lg (old Rails app) → lsd_lg_v2 (new LSD Base schema)
#
# Usage:
#   bundle exec rake migrate:lsd_lg
#
# Prerequisites:
#   - lsd_lg database must exist on the local postgres (old data)
#   - lsd_lg_v2 database must exist on the local postgres (new schema loaded)
#   - Both databases accessible via Unix socket (default postgres connection)
#
# Idempotent: re-running clears target tables and re-migrates.
# Run from the project root on the HOST (not inside Docker).

namespace :migrate do
  desc "Migrate data from lsd_lg (old) to lsd_lg_v2 (new schema)"
  task lsd_lg: :environment do
    require "pg"

    OLD_DB = "lsd_lg"
    NEW_DB = "lsd_lg_v2"

    puts "\n=== LSD-LG Migration ==="
    puts "Source: #{OLD_DB}  →  Target: #{NEW_DB}\n\n"

    src = PG.connect(dbname: OLD_DB)
    dst = PG.connect(dbname: NEW_DB)

    # ── Helpers ────────────────────────────────────────────────────────────────

    def q(conn, sql, *params)
      conn.exec_params(sql, params)
    end

    def insert(conn, table, row)
      cols = row.keys.map { |k| "\"#{k}\"" }.join(", ")
      placeholders = row.keys.each_with_index.map { |_, i| "$#{i + 1}" }.join(", ")
      vals = row.values
      conn.exec_params("INSERT INTO #{table} (#{cols}) VALUES (#{placeholders}) RETURNING id", vals).first["id"].to_i
    end

    def clear_table(conn, table)
      conn.exec("TRUNCATE #{table} RESTART IDENTITY CASCADE")
    end

    def wrap(conn)
      conn.exec("BEGIN")
      yield
      conn.exec("COMMIT")
    rescue => e
      conn.exec("ROLLBACK")
      raise e
    end

    # ── Status mapping ─────────────────────────────────────────────────────────
    # Old: states.name + track_statuses.name
    # New: status enum — draft=0, active=1, inactive=2, acquired=3, passed=4

    def map_status(state_name, track_name)
      return 4 if track_name == "Dead"                 # passed
      return 3 if state_name == "Published"            # acquired
      return 0 if state_name.nil? || state_name.strip.empty?  # draft
      1                                                # active
    end

    # ── Company role mapping ────────────────────────────────────────────────────
    # Old: 0=publisher, 1=agency, 2=film_agency
    # New integers: publisher=0, agency=1, film_agency=2, distributor=3, other=4, rights_holder=5, secondary_rights_holder=6
    COMPANY_ROLE_MAP = { 0 => 0, 1 => 1, 2 => 2 }.freeze  # old_int → new_int
    COMPANY_ROLE_RIGHTS_HOLDER = 5

    # Contact role mapping (integers)
    # Old: 0=editor, 1=agent, 2=film_agent
    # New: editor=0, agent=1, film_agent=2, author_contact=3, other=4
    CONTACT_ROLE_MAP = { 0 => 0, 1 => 1, 2 => 2 }.freeze  # old_int → new_int

    # ── Clear target tables ────────────────────────────────────────────────────
    puts "Clearing target tables..."
    %w[
      archive_notes book_memos client_activities reading_materials readers_reports
      book_authors book_companies book_contacts book_genres book_sub_genres
      book_client_types books authors contacts contact_companies company_subagents
      companies company_types territories client_types genres sub_genres roles users
      user_client_types reports report_books
    ].each { |t| dst.exec("TRUNCATE #{t} RESTART IDENTITY CASCADE") rescue nil }

    # ── ID maps (old_id → new_id) ──────────────────────────────────────────────
    company_type_map = {}
    territory_map    = {}
    genre_map        = {}
    subgenre_map     = {}
    client_type_map  = {}
    company_map      = {}
    contact_map      = {}
    author_map       = {}
    book_map         = {}
    user_map         = {}

    wrap(dst) do

      now = Time.current

      # ── 1. Company Types ─────────────────────────────────────────────────────
      puts "Migrating company types..."
      src.exec("SELECT id, name FROM company_types ORDER BY id").each do |row|
        new_id = insert(dst, "company_types", { "name" => row["name"], "created_at" => now, "updated_at" => now })
        company_type_map[row["id"].to_i] = new_id
      end
      puts "  → #{company_type_map.size} company types"

      # ── 2. Territories ───────────────────────────────────────────────────────
      puts "Migrating territories..."
      src.exec("SELECT id, name FROM territories ORDER BY id").each do |row|
        new_id = insert(dst, "territories", { "name" => row["name"], "created_at" => now, "updated_at" => now })
        territory_map[row["id"].to_i] = new_id
      end
      puts "  → #{territory_map.size} territories"

      # ── 3. Genres ────────────────────────────────────────────────────────────
      puts "Migrating genres..."
      src.exec("SELECT id, name FROM genres ORDER BY id").each do |row|
        new_id = insert(dst, "genres", { "name" => row["name"], "created_at" => now, "updated_at" => now })
        genre_map[row["id"].to_i] = new_id
      end
      puts "  → #{genre_map.size} genres"

      # ── 4. Sub-genres ────────────────────────────────────────────────────────
      # Use upsert to handle duplicates in the old data (e.g. "Commercial YA" x2)
      puts "Migrating sub-genres..."
      src.exec("SELECT id, name FROM subgenres ORDER BY id").each do |row|
        existing = dst.exec_params("SELECT id FROM sub_genres WHERE name = $1", [row["name"]]).first
        new_id = if existing
          existing["id"].to_i
        else
          insert(dst, "sub_genres", { "name" => row["name"], "created_at" => now, "updated_at" => now })
        end
        subgenre_map[row["id"].to_i] = new_id
      end
      puts "  → #{subgenre_map.values.uniq.size} sub-genres"

      # ── 5. Client Types ──────────────────────────────────────────────────────
      puts "Migrating client types..."
      src.exec("SELECT id, name FROM client_types ORDER BY id").each do |row|
        new_id = insert(dst, "client_types", { "name" => row["name"], "created_at" => now, "updated_at" => now })
        client_type_map[row["id"].to_i] = new_id
      end
      puts "  → #{client_type_map.size} client types"

      # ── 6. Companies ─────────────────────────────────────────────────────────
      puts "Migrating companies..."
      src.exec(<<~SQL).each do |row|
        SELECT c.id, c.name, c.url, c.notes, c.company_type_id,
               a.address1, a.address2, a.city, a.state, a.country, a.zip,
               p.main_number, p.fax_number
        FROM companies c
        LEFT JOIN addresses a ON a.owner_type = 'Company' AND a.owner_id = c.id
        LEFT JOIN phone_numbers p ON p.owner_type = 'Company' AND p.owner_id = c.id
        ORDER BY c.id
      SQL
        ct_id = row["company_type_id"] ? company_type_map[row["company_type_id"].to_i] : nil
        new_id = insert(dst, "companies", {
          "name"           => row["name"],
          "website"        => row["url"],
          "notes"          => row["notes"],
          "company_type_id" => ct_id,
          "address_line_1" => row["address1"],
          "address_line_2" => row["address2"],
          "city"           => row["city"],
          "state"          => row["state"],
          "postal_code"    => row["zip"],
          "country"        => row["country"],
          "phone"          => row["main_number"],
          "fax"            => row["fax_number"],
          "created_at"     => Time.current,
          "updated_at"     => Time.current,
        })
        company_map[row["id"].to_i] = new_id
      end
      puts "  → #{company_map.size} companies"

      # ── 6b. Company subagents (parent→child with territory) ──────────────────
      puts "Migrating company subagents..."
      count = 0
      src.exec("SELECT parent_id, child_id, territory_id FROM subagents").each do |row|
        parent_new = company_map[row["parent_id"].to_i]
        child_new  = company_map[row["child_id"].to_i]
        next unless parent_new && child_new
        territory_new = row["territory_id"] ? territory_map[row["territory_id"].to_i] : nil
        insert(dst, "company_subagents", {
          "company_id"         => parent_new,
          "subagent_company_id" => child_new,
          "territory_id"       => territory_new,
          "created_at"         => Time.current,
          "updated_at"         => Time.current,
        })
        count += 1
      end
      puts "  → #{count} subagent relationships"

      # ── 7. Contacts ──────────────────────────────────────────────────────────
      puts "Migrating contacts..."
      src.exec(<<~SQL).each do |row|
        SELECT c.id, c.firstname, c.lastname, c.email, c.notes, c.position, c.assistant_name,
               p.main_number
        FROM contacts c
        LEFT JOIN phone_numbers p ON p.owner_type = 'Contact' AND p.owner_id = c.id
        ORDER BY c.id
      SQL
        # Determine primary company from companies_contacts join
        primary_company = src.exec_params(
          "SELECT company_id FROM companies_contacts WHERE contact_id = $1 LIMIT 1",
          [row["id"]]
        ).first
        company_id_new = primary_company ? company_map[primary_company["company_id"].to_i] : nil

        # Handle contacts with no lastname — split from firstname if possible
        first = row["firstname"].to_s.strip
        last  = row["lastname"].to_s.strip
        if last.empty? && first.include?(" ")
          parts = first.split(" ")
          last  = parts.last
          first = parts[0..-2].join(" ")
        end
        last = first if last.empty?   # absolute fallback: use firstname as lastname too

        new_id = insert(dst, "contacts", {
          "first_name"     => first,
          "last_name"      => last,
          "email"          => row["email"],
          "phone"          => row["main_number"],
          "title"          => row["position"],
          "assistant_name" => row["assistant_name"],
          "notes"          => row["notes"],
          "created_at"     => now,
          "updated_at"     => now,
        })
        contact_map[row["id"].to_i] = new_id

        # Populate contact_companies for all companies this contact belongs to
        src.exec_params("SELECT company_id FROM companies_contacts WHERE contact_id = $1", [row["id"]]).each do |cc|
          comp_new = company_map[cc["company_id"].to_i]
          next unless comp_new
          dst.exec_params(
            "INSERT INTO contact_companies (contact_id, company_id, created_at, updated_at) VALUES ($1, $2, $3, $3) ON CONFLICT DO NOTHING",
            [new_id, comp_new, now]
          )
        end
      end
      puts "  → #{contact_map.size} contacts"

      # ── 8. Authors ───────────────────────────────────────────────────────────
      puts "Migrating authors..."
      src.exec("SELECT id, firstname, lastname, bio FROM authors ORDER BY id").each do |row|
        new_id = insert(dst, "authors", {
          "first_name"  => row["firstname"],
          "last_name"   => row["lastname"],
          "bio"         => row["bio"],
          "created_at"  => Time.current,
          "updated_at"  => Time.current,
        })
        author_map[row["id"].to_i] = new_id
      end
      puts "  → #{author_map.size} authors"

      # ── 9. Seed roles into lsd_lg_v2 ─────────────────────────────────────────
      puts "Seeding roles..."
      role_id_map = {}  # "admin" => new_role_id
      [["SuperAdmin", 100], ["Admin", 50], ["Scout", 25], ["Client", 10]].each do |name, level|
        id = insert(dst, "roles", { "name" => name, "hierarchy_level" => level, "created_at" => now, "updated_at" => now })
        role_id_map[name.downcase] = id
      end

      # ── 10. Users ────────────────────────────────────────────────────────────
      # Old roles: admin, scout, client → map to new role IDs
      puts "Migrating users..."
      src.exec(<<~SQL).each do |row|
        SELECT u.id, u.login, u.email, u.active, r.name AS role_name
        FROM users u
        LEFT JOIN roles r ON r.id = u.role_id
        ORDER BY u.id
      SQL
        old_role = row["role_name"].to_s.downcase
        role_id  = role_id_map[old_role] || role_id_map["client"]
        login    = row["login"].to_s.strip
        email    = row["email"].presence || "#{login.gsub(/\s/, "_").downcase}@migrated.local"
        parts      = login.split(" ")
        first_name = parts.length > 1 ? parts[0..-2].join(" ") : login
        last_name  = parts.length > 1 ? parts.last : login
        # Ensure unique email
        if dst.exec_params("SELECT 1 FROM users WHERE email = $1", [email]).any?
          email = "#{login.gsub(/[\s@]/, "_").downcase}_#{row["id"]}@migrated.local"
        end
        new_id = insert(dst, "users", {
          "first_name"      => first_name,
          "last_name"       => last_name,
          "email"           => email,
          "password_digest" => "$2a$12$placeholder_reset_required_xxxxxxxxxxxxxxxxxxxxxxxxxxx",
          "approved"        => row["active"] == "t",
          "role_id"         => role_id,
          "otp_secret"      => SecureRandom.hex(20),
          "created_at"      => now,
          "updated_at"      => now,
        })
        user_map[row["id"].to_i] = new_id
      end
      puts "  → #{user_map.size} users"
      puts "  ⚠  All migrated users need password reset before first login."

      # User → client type assignments
      src.exec("SELECT user_id, client_type_id FROM client_types_users").each do |row|
        u_new  = user_map[row["user_id"].to_i]
        ct_new = client_type_map[row["client_type_id"].to_i]
        next unless u_new && ct_new
        dst.exec_params(
          "INSERT INTO user_client_types (user_id, client_type_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
          [u_new, ct_new]
        )
      end

      # ── 10. Books ────────────────────────────────────────────────────────────
      puts "Migrating books..."
      src.exec(<<~SQL).each do |row|
        SELECT b.*,
               s.name  AS state_name,
               ts.name AS track_status_name
        FROM books b
        LEFT JOIN states s ON s.id = b.state_id
        LEFT JOIN track_statuses ts ON ts.id = b.track_status_id
        ORDER BY b.id
      SQL
        status_int = map_status(row["state_name"], row["track_status_name"])
        scout_id   = row["scout_id"]  ? user_map[row["scout_id"].to_i]  : nil
        creator_id = row["creator_id"] ? user_map[row["creator_id"].to_i] : nil

        new_id = insert(dst, "books", {
          "title"            => row["title"],
          "subtitle"         => row["subtitle"],
          "old_title"        => [row["old_title"], row["previous_title"]].compact.uniq.join(" / ").presence,
          "synopsis"         => row["synopsis"],
          "log_line"         => row["log_line"],
          "pub_info"         => row["deal_terms"],
          "confidential"     => row["confidential"] == "t",
          "material_to_read" => row["to_read"] == "t",
          "status"           => status_int,
          "publication_year" => row["publication_year"],
          "publication_season" => row["publication_season"],
          "delivery_date"    => row["delivery_date"],
          "followup_date"    => row["followup_date"],
          "primary_scout_id" => scout_id,
          "pages"            => row["pages"],
          "format"           => row["format"],
          "created_at"       => row["created_at"] || Time.current,
          "updated_at"       => row["updated_at"] || Time.current,
        })
        book_map[row["id"].to_i] = new_id

        # ── Book → Genres ─────────────────────────────────────────────────────
        if row["genre_id"]
          g_new = genre_map[row["genre_id"].to_i]
          if g_new
            dst.exec_params(
              "INSERT INTO book_genres (book_id, genre_id, created_at, updated_at) VALUES ($1, $2, $3, $3) ON CONFLICT DO NOTHING",
              [new_id, g_new, now]
            )
          end
        end

        # ── Film tracking ─────────────────────────────────────────────────────
        has_film_data = %w[film_info film_option film_option_date sold_for_film].any? { |f| row[f].present? && row[f] != "f" }
        if has_film_data
          film_flag = case
                      when row["sold_for_film"] == "t" then 2  # pub_buzz
                      when row["film_option"]  == "t" then 1   # out_for_film
                      else 0
                      end
          dst.exec_params(<<~SQL, [new_id, row["film_info"], row["film_option_date"], film_flag, Time.current, Time.current])
            INSERT INTO film_trackings (book_id, film_synopsis, film_option_date, film_flag, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (book_id) DO NOTHING
          SQL
        end

        # ── Notes → book_memos ────────────────────────────────────────────────
        note_parts = {
          "Comments"        => row["comments"],
          "Tracking Notes"  => row["tracking_notes"],
          "General Notes"   => row["general_notes"],
          "Subagent Notes"  => row["subagent_notes"],
          "Options"         => row["options"],
        }.select { |_, v| v.present? }

        note_parts.each do |label, content|
          dst.exec_params(
            "INSERT INTO book_memos (book_id, note, created_at, updated_at) VALUES ($1, $2, $3, $3)",
            [new_id, "**#{label}**\n\n#{content}", row["created_at"] || Time.current]
          )
        end

        # ── Notes → archive_notes ─────────────────────────────────────────────
        archive_parts = {
          "Private Notes"          => row["private_notes"],
          "Private Tracking Notes" => row["private_tracking_notes"],
          "Archive Information"    => row["archive_information"],
        }.select { |_, v| v.present? }

        archive_parts.each do |label, content|
          dst.exec_params(
            "INSERT INTO archive_notes (book_id, note, created_at, updated_at) VALUES ($1, $2, $3, $3)",
            [new_id, "**#{label}**\n\n#{content}", row["created_at"] || Time.current]
          )
        end

        # ── Reader report → readers_reports ───────────────────────────────────
        if row["reader_report"].present?
          reader_id = row["reader_id"] ? user_map[row["reader_id"].to_i] : nil
          dst.exec_params(<<~SQL, [new_id, reader_id, row["reader_report_date"], row["reader_report"], Time.current, Time.current])
            INSERT INTO readers_reports (book_id, reader_id, report_date, comments, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6)
          SQL
        end
      end
      puts "  → #{book_map.size} books"

      # ── 11. Book → Sub-genres ─────────────────────────────────────────────
      puts "Migrating book sub-genre links..."
      count = 0
      src.exec("SELECT book_id, subgenre_id FROM books_subgenres").each do |row|
        b_new = book_map[row["book_id"].to_i]
        s_new = subgenre_map[row["subgenre_id"].to_i]
        next unless b_new && s_new
        dst.exec_params(
          "INSERT INTO book_sub_genres (book_id, sub_genre_id, created_at, updated_at) VALUES ($1, $2, $3, $3) ON CONFLICT DO NOTHING",
          [b_new, s_new, now]
        )
        count += 1
      end
      puts "  → #{count} book/sub-genre links"

      # ── 12. Book → Client Types ───────────────────────────────────────────
      puts "Migrating book client type links..."
      count = 0
      src.exec("SELECT book_id, client_type_id FROM books_client_types").each do |row|
        b_new  = book_map[row["book_id"].to_i]
        ct_new = client_type_map[row["client_type_id"].to_i]
        next unless b_new && ct_new
        dst.exec_params(
          "INSERT INTO book_client_types (book_id, client_type_id, created_at, updated_at) VALUES ($1, $2, $3, $3) ON CONFLICT DO NOTHING",
          [b_new, ct_new, now]
        )
        count += 1
      end
      puts "  → #{count} book/client-type links"

      # ── 13. Book → Authors ────────────────────────────────────────────────
      puts "Migrating book author links..."
      count = 0
      src.exec("SELECT book_id, author_id FROM authors_books").each do |row|
        b_new = book_map[row["book_id"].to_i]
        a_new = author_map[row["author_id"].to_i]
        next unless b_new && a_new
        dst.exec_params(
          "INSERT INTO book_authors (book_id, author_id, role, created_at, updated_at) VALUES ($1, $2, 0, $3, $3) ON CONFLICT DO NOTHING",
          [b_new, a_new, Time.current]
        )
        count += 1
      end
      puts "  → #{count} book/author links"

      # ── 14. Book → Companies ─────────────────────────────────────────────
      puts "Migrating book companies..."
      count = 0
      src.exec("SELECT book_id, company_id, company_role FROM book_companies").each do |row|
        b_new    = book_map[row["book_id"].to_i]
        c_new    = company_map[row["company_id"].to_i]
        role_str = COMPANY_ROLE_MAP[row["company_role"].to_i]
        next unless b_new && c_new && role_str
        dst.exec_params(
          "INSERT INTO book_companies (book_id, company_id, role, created_at, updated_at) VALUES ($1, $2, $3, $4, $4) ON CONFLICT DO NOTHING",
          [b_new, c_new, role_str, Time.current]
        )
        count += 1
      end
      puts "  → #{count} book/company links"

      # ── 15. Book → Contacts ───────────────────────────────────────────────
      puts "Migrating book contacts..."
      count = 0
      src.exec("SELECT book_id, contact_id, contact_role FROM book_contacts").each do |row|
        b_new    = book_map[row["book_id"].to_i]
        c_new    = contact_map[row["contact_id"].to_i]
        role_str = CONTACT_ROLE_MAP[row["contact_role"].to_i]
        next unless b_new && c_new && role_str
        dst.exec_params(
          "INSERT INTO book_contacts (book_id, contact_id, role, created_at, updated_at) VALUES ($1, $2, $3, $4, $4) ON CONFLICT DO NOTHING",
          [b_new, c_new, role_str, Time.current]
        )
        count += 1
      end
      puts "  → #{count} book/contact links"

      # ── 16. Rights holders → book_companies ──────────────────────────────
      # Stored as role='rights_holder'. Territory info appended to rights_sold.
      puts "Migrating rights holders..."
      count = 0
      src.exec("SELECT rh.book_id, rh.company_id, rh.territory_id, t.name AS territory_name FROM rights_holders rh LEFT JOIN territories t ON t.id = rh.territory_id").each do |row|
        b_new = book_map[row["book_id"].to_i]
        c_new = company_map[row["company_id"].to_i]
        next unless b_new && c_new
        dst.exec_params(
          "INSERT INTO book_companies (book_id, company_id, role, created_at, updated_at) VALUES ($1, $2, $3, $4, $4) ON CONFLICT DO NOTHING",
          [b_new, c_new, COMPANY_ROLE_RIGHTS_HOLDER, now]
        )
        # Append territory to rights_sold text if present
        if row["territory_name"].present?
          dst.exec_params(
            "UPDATE books SET rights_sold = COALESCE(rights_sold || E'\\n', '') || $2 WHERE id = $1",
            [b_new, row["territory_name"]]
          )
        end
        count += 1
      end
      puts "  → #{count} rights holder links"

      # ── 17. Reports ───────────────────────────────────────────────────────
      # Old report_type.name → new report_type enum
      puts "Migrating reports..."
      report_type_map_str = {
        "Reading List"      => 0,
        "Follow Up List"    => 1,
        "YA Highlights"     => 2,
        "Adult Highlights"  => 3,
        "Netflix Report"    => 4,
        "Film Memo"         => 5,
      }

      report_id_map = {}
      src.exec(<<~SQL).each do |row|
        SELECT r.id, r.title, r.body, r.report_date, r.sent_status, r.footer, rt.name AS type_name
        FROM reports r
        LEFT JOIN report_types rt ON rt.id = r.report_type_id
        ORDER BY r.id
      SQL
        report_type_int = report_type_map_str[row["type_name"]] || 0
        new_id = insert(dst, "reports", {
          "title"       => row["title"],
          "body"        => row["body"],
          "footer"      => row["footer"],
          "report_date" => row["report_date"],
          "sent"        => row["sent_status"] == "t",
          "report_type" => report_type_int,
          "created_at"  => Time.current,
          "updated_at"  => Time.current,
        })
        report_id_map[row["id"].to_i] = new_id
      end

      # Report → Book links
      count = 0
      src.exec("SELECT book_id, report_id FROM books_reports").each_with_index do |row, pos|
        b_new = book_map[row["book_id"].to_i]
        r_new = report_id_map[row["report_id"].to_i]
        next unless b_new && r_new
        dst.exec_params(
          "INSERT INTO report_books (book_id, report_id, position, created_at, updated_at) VALUES ($1, $2, $3, $4, $4) ON CONFLICT DO NOTHING",
          [b_new, r_new, pos, Time.current]
        )
        count += 1
      end
      puts "  → #{report_id_map.size} reports, #{count} report/book links"

    end # transaction

    src.close
    dst.close

    puts "\n=== Migration complete ==="
    puts "Next steps:"
    puts "  1. Review lsd_lg_v2 in psql or a DB tool"
    puts "  2. Users need passwords reset — they have placeholder digests"
    puts "  3. Copy config/fields_lsd_lg.yml to the lsd_lg instance as config/fields.yml"
    puts "  4. pg_dump lsd_lg_v2 and restore into the Docker postgres for that instance"
  end
end
