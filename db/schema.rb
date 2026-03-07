# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_07_174344) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "archive_notes", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_archive_notes_on_book_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.integer "resource_id"
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "authors", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.index "(((TRIM(BOTH FROM last_name) || ', '::text) || TRIM(BOTH FROM COALESCE(first_name, ''::character varying)))) gin_trgm_ops", name: "index_authors_on_name_trgm", using: :gin
    t.index ["discarded_at"], name: "index_authors_on_discarded_at"
    t.index ["last_name", "first_name"], name: "index_authors_on_last_name_and_first_name"
    t.index ["last_name"], name: "index_authors_on_last_name"
  end

  create_table "book_authors", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_book_authors_on_author_id"
    t.index ["book_id", "author_id", "role"], name: "index_book_authors_on_book_id_and_author_id_and_role", unique: true
    t.index ["book_id"], name: "index_book_authors_on_book_id"
  end

  create_table "book_client_types", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "client_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "client_type_id"], name: "index_book_client_types_on_book_id_and_client_type_id", unique: true
    t.index ["book_id"], name: "index_book_client_types_on_book_id"
    t.index ["client_type_id"], name: "index_book_client_types_on_client_type_id"
  end

  create_table "book_companies", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "company_id", "role"], name: "index_book_companies_on_book_id_and_company_id_and_role", unique: true
    t.index ["book_id"], name: "index_book_companies_on_book_id"
    t.index ["company_id"], name: "index_book_companies_on_company_id"
  end

  create_table "book_contacts", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "contact_id", "role"], name: "index_book_contacts_on_book_id_and_contact_id_and_role", unique: true
    t.index ["book_id"], name: "index_book_contacts_on_book_id"
    t.index ["contact_id"], name: "index_book_contacts_on_contact_id"
  end

  create_table "book_genres", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "genre_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "genre_id"], name: "index_book_genres_on_book_id_and_genre_id", unique: true
    t.index ["book_id"], name: "index_book_genres_on_book_id"
    t.index ["genre_id"], name: "index_book_genres_on_genre_id"
  end

  create_table "book_memos", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_book_memos_on_book_id"
  end

  create_table "book_searches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.jsonb "params", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_book_searches_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_book_searches_on_user_id"
  end

  create_table "book_sub_genres", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "sub_genre_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "sub_genre_id"], name: "index_book_sub_genres_on_book_id_and_sub_genre_id", unique: true
    t.index ["book_id"], name: "index_book_sub_genres_on_book_id"
    t.index ["sub_genre_id"], name: "index_book_sub_genres_on_sub_genre_id"
  end

  create_table "book_updates", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_book_updates_on_book_id"
  end

  create_table "books", force: :cascade do |t|
    t.boolean "confidential", default: false, null: false
    t.boolean "confidential_material", default: false, null: false
    t.boolean "confidential_report", default: false, null: false
    t.datetime "created_at", null: false
    t.date "delivery_date"
    t.datetime "discarded_at"
    t.date "followup_date"
    t.string "format"
    t.bigint "last_updated_by_id"
    t.boolean "lead_title", default: false, null: false
    t.text "log_line"
    t.text "log_line_plain"
    t.text "material"
    t.text "material_plain"
    t.boolean "material_to_read", default: false, null: false
    t.text "notes"
    t.text "notes_plain"
    t.string "old_title"
    t.integer "pages"
    t.bigint "primary_scout_id"
    t.text "pub_info"
    t.text "pub_info_plain"
    t.string "publication_season"
    t.integer "publication_year"
    t.text "readers_report"
    t.text "rights_sold"
    t.text "rights_sold_plain"
    t.bigint "secondary_scout_id"
    t.integer "status", default: 0, null: false
    t.string "subtitle"
    t.text "synopsis"
    t.text "synopsis_plain"
    t.string "title"
    t.boolean "tracking_material", default: false, null: false
    t.string "update_tagline"
    t.datetime "updated_at", null: false
    t.index ["confidential"], name: "index_books_on_confidential"
    t.index ["discarded_at"], name: "index_books_on_discarded_at"
    t.index ["last_updated_by_id"], name: "index_books_on_last_updated_by_id"
    t.index ["log_line_plain"], name: "index_books_on_log_line_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["material_plain"], name: "index_books_on_material_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["notes_plain"], name: "index_books_on_notes_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["primary_scout_id"], name: "index_books_on_primary_scout_id"
    t.index ["pub_info_plain"], name: "index_books_on_pub_info_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["publication_year"], name: "index_books_on_publication_year"
    t.index ["rights_sold_plain"], name: "index_books_on_rights_sold_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["secondary_scout_id"], name: "index_books_on_secondary_scout_id"
    t.index ["status"], name: "index_books_on_status"
    t.index ["synopsis_plain"], name: "index_books_on_synopsis_plain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["title"], name: "index_books_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["updated_at"], name: "index_books_on_updated_at"
  end

  create_table "client_activities", force: :cascade do |t|
    t.string "activity_type"
    t.bigint "book_id", null: false
    t.bigint "company_id"
    t.bigint "contact_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.date "date"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_client_activities_on_book_id"
  end

  create_table "client_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_client_types_on_name", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.bigint "company_type_id"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "fax"
    t.string "name", null: false
    t.boolean "nest_subagents", default: false, null: false
    t.text "notes"
    t.string "phone"
    t.string "postal_code"
    t.string "state"
    t.datetime "updated_at", null: false
    t.boolean "viewable_by_clients", default: true, null: false
    t.string "website"
    t.index ["company_type_id"], name: "index_companies_on_company_type_id"
    t.index ["discarded_at"], name: "index_companies_on_discarded_at"
    t.index ["name"], name: "index_companies_on_name"
  end

  create_table "company_subagents", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "subagent_company_id", null: false
    t.bigint "territory_id"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_subagents_on_company_id"
    t.index ["subagent_company_id"], name: "index_company_subagents_on_subagent_company_id"
    t.index ["territory_id"], name: "index_company_subagents_on_territory_id"
  end

  create_table "company_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_company_types_on_name", unique: true
  end

  create_table "contact_companies", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contact_companies_on_company_id"
    t.index ["contact_id", "company_id"], name: "index_contact_companies_on_contact_id_and_company_id", unique: true
    t.index ["contact_id"], name: "index_contact_companies_on_contact_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "assistant_name"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "direct_number"
    t.datetime "discarded_at"
    t.string "email"
    t.string "fax_number"
    t.string "first_name", null: false
    t.string "home_number"
    t.string "last_name", null: false
    t.string "mobile_number"
    t.text "notes"
    t.string "phone"
    t.string "state"
    t.string "title"
    t.bigint "tracked_by_id"
    t.datetime "updated_at", null: false
    t.string "zip"
    t.index ["discarded_at"], name: "index_contacts_on_discarded_at"
    t.index ["last_name", "first_name"], name: "index_contacts_on_last_name_and_first_name"
    t.index ["tracked_by_id"], name: "index_contacts_on_tracked_by_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "custom_field_values", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "custom_field_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value_json"
    t.index ["book_id", "custom_field_id"], name: "index_custom_field_values_on_book_id_and_custom_field_id", unique: true
    t.index ["book_id"], name: "index_custom_field_values_on_book_id"
    t.index ["custom_field_id"], name: "index_custom_field_values_on_custom_field_id"
  end

  create_table "custom_fields", force: :cascade do |t|
    t.boolean "active", default: true
    t.jsonb "choices", default: []
    t.datetime "created_at", null: false
    t.integer "field_type", null: false
    t.string "group_name", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.boolean "required", default: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_report_template_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "custom_report_template_id", null: false
    t.string "field_key", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["custom_report_template_id"], name: "idx_on_custom_report_template_id_37ea792b8a"
  end

  create_table "custom_report_template_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "custom_report_template_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["custom_report_template_id"], name: "idx_on_custom_report_template_id_018db7e7d1"
  end

  create_table "custom_report_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_custom_report_templates_on_created_by_id"
    t.index ["name"], name: "index_custom_report_templates_on_name", unique: true
  end

  create_table "film_activities", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "client"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_film_activities_on_book_id"
    t.index ["company_id"], name: "index_film_activities_on_company_id"
  end

  create_table "film_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_film_genres_on_name", unique: true
    t.index ["name"], name: "index_film_genres_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "film_tracking_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "film_genre_id", null: false
    t.bigint "film_tracking_id", null: false
    t.datetime "updated_at", null: false
    t.index ["film_genre_id"], name: "index_film_tracking_genres_on_film_genre_id"
    t.index ["film_tracking_id", "film_genre_id"], name: "index_film_tracking_genres_unique", unique: true
    t.index ["film_tracking_id"], name: "index_film_tracking_genres_on_film_tracking_id"
  end

  create_table "film_trackings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "category"
    t.text "comments"
    t.datetime "created_at", null: false
    t.boolean "enable_red_text", default: false, null: false
    t.string "film_flag"
    t.text "film_option"
    t.date "film_option_date"
    t.text "film_synopsis"
    t.text "material"
    t.boolean "off", default: false, null: false
    t.boolean "pub_buzz", default: false, null: false
    t.text "readers_thoughts"
    t.text "red_text"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_film_trackings_on_book_id", unique: true
  end

  create_table "genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genres_on_name", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "readers_reports", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.text "film_commentary"
    t.integer "film_recommended"
    t.text "publishing_recommendation"
    t.integer "publishing_recommended"
    t.bigint "reader_id"
    t.bigint "reading_material_id"
    t.date "report_date"
    t.string "sent_to"
    t.text "synopsis"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_readers_reports_on_book_id"
    t.index ["reader_id"], name: "index_readers_reports_on_reader_id"
    t.index ["reading_material_id"], name: "index_readers_reports_on_reading_material_id"
  end

  create_table "reading_materials", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "material"
    t.integer "number_of_pages"
    t.string "reader"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_reading_materials_on_book_id"
  end

  create_table "recovery_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "used", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_recovery_codes_on_user_id"
  end

  create_table "report_books", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.string "custom_section"
    t.integer "position", default: 0, null: false
    t.bigint "report_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_report_books_on_book_id"
    t.index ["report_id", "book_id"], name: "index_report_books_on_report_id_and_book_id", unique: true
    t.index ["report_id", "position"], name: "index_report_books_on_report_id_and_position"
    t.index ["report_id"], name: "index_report_books_on_report_id"
  end

  create_table "report_client_types", force: :cascade do |t|
    t.bigint "client_type_id", null: false
    t.datetime "created_at", null: false
    t.bigint "report_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_type_id"], name: "index_report_client_types_on_client_type_id"
    t.index ["report_id", "client_type_id"], name: "index_report_client_types_on_report_id_and_client_type_id", unique: true
    t.index ["report_id"], name: "index_report_client_types_on_report_id"
  end

  create_table "reports", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "custom_report_template_id"
    t.text "footer"
    t.boolean "pinned", default: false, null: false
    t.text "rendered_content"
    t.date "report_date"
    t.integer "report_type", default: 0, null: false
    t.boolean "sent", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_reports_on_created_by_id"
    t.index ["custom_report_template_id"], name: "index_reports_on_custom_report_template_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "hierarchy_level"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "sub_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sub_genres_on_name", unique: true
  end

  create_table "territories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_territories_on_name", unique: true
  end

  create_table "user_client_types", force: :cascade do |t|
    t.bigint "client_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_type_id"], name: "index_user_client_types_on_client_type_id"
    t.index ["user_id", "client_type_id"], name: "index_user_client_types_on_user_id_and_client_type_id", unique: true
    t.index ["user_id"], name: "index_user_client_types_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "otp_required_for_sign_in", default: false, null: false
    t.string "otp_secret", null: false
    t.string "password_digest", null: false
    t.string "provider"
    t.bigint "role_id"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["uid"], name: "index_users_on_uid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "archive_notes", "books"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "book_authors", "authors"
  add_foreign_key "book_authors", "books"
  add_foreign_key "book_client_types", "books"
  add_foreign_key "book_client_types", "client_types"
  add_foreign_key "book_companies", "books"
  add_foreign_key "book_companies", "companies"
  add_foreign_key "book_contacts", "books"
  add_foreign_key "book_contacts", "contacts"
  add_foreign_key "book_genres", "books"
  add_foreign_key "book_genres", "genres"
  add_foreign_key "book_memos", "books"
  add_foreign_key "book_searches", "users"
  add_foreign_key "book_sub_genres", "books"
  add_foreign_key "book_sub_genres", "sub_genres"
  add_foreign_key "book_updates", "books"
  add_foreign_key "books", "users", column: "last_updated_by_id"
  add_foreign_key "books", "users", column: "primary_scout_id"
  add_foreign_key "books", "users", column: "secondary_scout_id"
  add_foreign_key "client_activities", "books"
  add_foreign_key "companies", "company_types"
  add_foreign_key "company_subagents", "companies"
  add_foreign_key "company_subagents", "companies", column: "subagent_company_id"
  add_foreign_key "company_subagents", "territories"
  add_foreign_key "contact_companies", "companies"
  add_foreign_key "contact_companies", "contacts"
  add_foreign_key "contacts", "users", column: "tracked_by_id"
  add_foreign_key "conversations", "users"
  add_foreign_key "custom_field_values", "books"
  add_foreign_key "custom_field_values", "custom_fields"
  add_foreign_key "custom_report_template_fields", "custom_report_templates"
  add_foreign_key "custom_report_template_sections", "custom_report_templates"
  add_foreign_key "custom_report_templates", "users", column: "created_by_id"
  add_foreign_key "film_activities", "books"
  add_foreign_key "film_activities", "companies"
  add_foreign_key "film_tracking_genres", "film_genres"
  add_foreign_key "film_tracking_genres", "film_trackings"
  add_foreign_key "film_trackings", "books"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "readers_reports", "books"
  add_foreign_key "readers_reports", "reading_materials"
  add_foreign_key "readers_reports", "users", column: "reader_id"
  add_foreign_key "reading_materials", "books"
  add_foreign_key "recovery_codes", "users"
  add_foreign_key "report_books", "books"
  add_foreign_key "report_books", "reports"
  add_foreign_key "report_client_types", "client_types"
  add_foreign_key "report_client_types", "reports"
  add_foreign_key "reports", "custom_report_templates"
  add_foreign_key "reports", "users", column: "created_by_id"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_client_types", "client_types"
  add_foreign_key "user_client_types", "users"
  add_foreign_key "users", "roles"
end
