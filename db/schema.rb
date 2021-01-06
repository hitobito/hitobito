# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_05_120000) do

  create_table "action_text_rich_texts", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", size: :long
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "additional_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "contactable_type", null: false
    t.integer "contactable_id", null: false
    t.string "email", null: false
    t.string "label"
    t.boolean "public", default: true, null: false
    t.boolean "mailings", default: false, null: false
    t.index ["contactable_id", "contactable_type"], name: "index_additional_emails_on_contactable_id_and_contactable_type"
  end

  create_table "addresses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "street_short", limit: 128, null: false
    t.string "street_short_old", limit: 128, null: false
    t.string "street_long", limit: 128, null: false
    t.string "street_long_old", limit: 128, null: false
    t.string "town", limit: 128, null: false
    t.integer "zip_code", null: false
    t.string "state", limit: 128, null: false
    t.text "numbers", size: :medium
    t.index ["zip_code", "street_short"], name: "index_addresses_on_zip_code_and_street_short"
  end

  create_table "custom_content_translations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "custom_content_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "label", null: false
    t.string "subject"
    t.index ["custom_content_id"], name: "index_custom_content_translations_on_custom_content_id"
    t.index ["locale"], name: "index_custom_content_translations_on_locale"
  end

  create_table "custom_contents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "key", null: false
    t.string "placeholders_required"
    t.string "placeholders_optional"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler", size: :medium
    t.text "last_error", size: :medium
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "delayed_workers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.datetime "last_heartbeat_at"
    t.string "host_name"
    t.string "label"
  end

  create_table "event_answers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "participation_id", null: false
    t.integer "question_id", null: false
    t.string "answer"
    t.index ["participation_id", "question_id"], name: "index_event_answers_on_participation_id_and_question_id", unique: true
  end

  create_table "event_applications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "priority_1_id", null: false
    t.integer "priority_2_id"
    t.integer "priority_3_id"
    t.boolean "approved", default: false, null: false
    t.boolean "rejected", default: false, null: false
    t.boolean "waiting_list", default: false, null: false
    t.text "waiting_list_comment", size: :medium
  end

  create_table "event_attachments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id", null: false
    t.string "file", null: false
    t.index ["event_id"], name: "index_event_attachments_on_event_id"
  end

  create_table "event_dates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id", null: false
    t.string "label"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.string "location"
    t.index ["event_id", "start_at"], name: "index_event_dates_on_event_id_and_start_at"
    t.index ["event_id"], name: "index_event_dates_on_event_id"
  end

  create_table "event_kind_qualification_kinds", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_kind_id", null: false
    t.integer "qualification_kind_id", null: false
    t.string "category", null: false
    t.string "role", null: false
    t.integer "grouping"
    t.index ["category"], name: "index_event_kind_qualification_kinds_on_category"
    t.index ["role"], name: "index_event_kind_qualification_kinds_on_role"
  end

  create_table "event_kind_translations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_kind_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "label", null: false
    t.string "short_name"
    t.text "general_information", size: :medium
    t.text "application_conditions", size: :medium
    t.index ["event_kind_id"], name: "index_event_kind_translations_on_event_kind_id"
    t.index ["locale"], name: "index_event_kind_translations_on_locale"
  end

  create_table "event_kinds", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "minimum_age"
  end

  create_table "event_participations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "person_id", null: false
    t.text "additional_information", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false, null: false
    t.integer "application_id"
    t.boolean "qualified"
    t.index ["application_id"], name: "index_event_participations_on_application_id"
    t.index ["event_id", "person_id"], name: "index_event_participations_on_event_id_and_person_id", unique: true
    t.index ["event_id"], name: "index_event_participations_on_event_id"
    t.index ["person_id"], name: "index_event_participations_on_person_id"
  end

  create_table "event_questions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.string "question"
    t.string "choices"
    t.boolean "multiple_choices", default: false, null: false
    t.boolean "required", default: false, null: false
    t.boolean "admin", default: false, null: false
    t.index ["event_id"], name: "index_event_questions_on_event_id"
  end

  create_table "event_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "type", null: false
    t.integer "participation_id", null: false
    t.string "label"
    t.index ["participation_id"], name: "index_event_roles_on_participation_id"
    t.index ["type"], name: "index_event_roles_on_type"
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "type"
    t.string "name", null: false
    t.string "number"
    t.string "motto"
    t.string "cost"
    t.integer "maximum_participants"
    t.integer "contact_id"
    t.text "description", size: :medium
    t.text "location", size: :medium
    t.date "application_opening_at"
    t.date "application_closing_at"
    t.text "application_conditions", size: :medium
    t.integer "kind_id"
    t.string "state", limit: 60
    t.boolean "priorization", default: false, null: false
    t.boolean "requires_approval", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "participant_count", default: 0
    t.integer "application_contact_id"
    t.boolean "external_applications", default: false
    t.integer "applicant_count", default: 0
    t.integer "teamer_count", default: 0
    t.boolean "signature"
    t.boolean "signature_confirmation"
    t.string "signature_confirmation_text"
    t.integer "creator_id"
    t.integer "updater_id"
    t.boolean "applications_cancelable", default: false, null: false
    t.text "required_contact_attrs", size: :medium
    t.text "hidden_contact_attrs", size: :medium
    t.boolean "display_booking_info", default: true, null: false
    t.boolean "participations_visible", default: false, null: false
    t.index ["kind_id"], name: "index_events_on_kind_id"
  end

  create_table "events_groups", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.integer "group_id"
    t.index ["event_id", "group_id"], name: "index_events_groups_on_event_id_and_group_id", unique: true
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.string "name", null: false
    t.string "short_name", limit: 31
    t.string "type", null: false
    t.string "email"
    t.text "address", size: :medium
    t.integer "zip_code"
    t.string "town"
    t.string "country"
    t.integer "contact_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "layer_group_id"
    t.integer "creator_id"
    t.integer "updater_id"
    t.integer "deleter_id"
    t.boolean "require_person_add_requests", default: false, null: false
    t.text "description", size: :medium
    t.string "logo"
    t.index ["layer_group_id"], name: "index_groups_on_layer_group_id"
    t.index ["lft", "rgt"], name: "index_groups_on_lft_and_rgt"
    t.index ["parent_id"], name: "index_groups_on_parent_id"
    t.index ["type"], name: "index_groups_on_type"
  end

  create_table "help_text_translations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "help_text_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["help_text_id"], name: "index_help_text_translations_on_help_text_id"
    t.index ["locale"], name: "index_help_text_translations_on_locale"
  end

  create_table "help_texts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "controller", limit: 100, null: false
    t.string "model", limit: 100
    t.string "kind", limit: 100, null: false
    t.string "name", limit: 100, null: false
    t.index ["controller", "model", "kind", "name"], name: "index_help_texts_fields", unique: true
  end

  create_table "invoice_articles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "number"
    t.string "name", null: false
    t.text "description", size: :medium
    t.string "category"
    t.decimal "unit_cost", precision: 12, scale: 2
    t.decimal "vat_rate", precision: 5, scale: 2
    t.string "cost_center"
    t.string "account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_id", null: false
    t.index ["number", "group_id"], name: "index_invoice_articles_on_number_and_group_id", unique: true
  end

  create_table "invoice_configs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "sequence_number", default: 1, null: false
    t.integer "due_days", default: 30, null: false
    t.integer "group_id", null: false
    t.text "address", size: :medium
    t.text "payment_information", size: :medium
    t.string "account_number"
    t.string "iban"
    t.string "payment_slip", default: "ch_es", null: false
    t.text "beneficiary", size: :medium
    t.text "payee", size: :medium
    t.string "participant_number"
    t.string "email"
    t.string "participant_number_internal"
    t.string "vat_number"
    t.string "currency", default: "CHF", null: false
    t.index ["group_id"], name: "index_invoice_configs_on_group_id"
  end

  create_table "invoice_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.string "name", null: false
    t.text "description", size: :medium
    t.decimal "vat_rate", precision: 5, scale: 2
    t.decimal "unit_cost", precision: 12, scale: 2, null: false
    t.integer "count", default: 1, null: false
    t.string "cost_center"
    t.string "account"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.string "sequence_number", null: false
    t.string "state", default: "draft", null: false
    t.string "esr_number", null: false
    t.text "description", size: :medium
    t.string "recipient_email"
    t.text "recipient_address", size: :medium
    t.date "sent_at"
    t.date "due_at"
    t.integer "group_id", null: false
    t.integer "recipient_id"
    t.decimal "total", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account_number"
    t.text "address", size: :medium
    t.date "issued_at"
    t.string "iban"
    t.text "payment_purpose", size: :medium
    t.text "payment_information", size: :medium
    t.string "payment_slip", default: "ch_es", null: false
    t.text "beneficiary", size: :medium
    t.text "payee", size: :medium
    t.string "participant_number"
    t.integer "creator_id"
    t.string "participant_number_internal"
    t.string "vat_number"
    t.string "currency", default: "CHF", null: false
    t.string "reference", null: false
    t.index ["esr_number"], name: "index_invoices_on_esr_number"
    t.index ["group_id"], name: "index_invoices_on_group_id"
    t.index ["recipient_id"], name: "index_invoices_on_recipient_id"
    t.index ["sequence_number"], name: "index_invoices_on_sequence_number"
  end

  create_table "label_format_translations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "label_format_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name", null: false
    t.index ["label_format_id"], name: "index_label_format_translations_on_label_format_id"
    t.index ["locale"], name: "index_label_format_translations_on_locale"
  end

  create_table "label_formats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "page_size", default: "A4", null: false
    t.boolean "landscape", default: false, null: false
    t.float "font_size", default: 11.0, null: false
    t.float "width", null: false
    t.float "height", null: false
    t.integer "count_horizontal", null: false
    t.integer "count_vertical", null: false
    t.float "padding_top", null: false
    t.float "padding_left", null: false
    t.integer "person_id"
    t.boolean "nickname", default: false, null: false
    t.string "pp_post", limit: 23
  end

  create_table "locations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.string "canton", limit: 2, null: false
    t.string "zip_code", null: false
    t.index ["zip_code", "canton", "name"], name: "index_locations_on_zip_code_and_canton_and_name", unique: true
  end

  create_table "mail_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "mail_from"
    t.string "mail_hash"
    t.integer "status", default: 0
    t.string "mailing_list_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "message_id"
    t.index ["mail_hash"], name: "index_mail_logs_on_mail_hash"
    t.index ["message_id"], name: "index_mail_logs_on_message_id"
  end

  create_table "mailing_lists", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.integer "group_id", null: false
    t.text "description", size: :medium
    t.string "publisher"
    t.string "mail_name"
    t.string "additional_sender"
    t.boolean "subscribable", default: false, null: false
    t.boolean "subscribers_may_post", default: false, null: false
    t.boolean "anyone_may_post", default: false, null: false
    t.string "preferred_labels"
    t.boolean "delivery_report", default: false, null: false
    t.boolean "main_email", default: false
    t.string "mailchimp_api_key"
    t.string "mailchimp_list_id"
    t.boolean "mailchimp_syncing", default: false
    t.datetime "mailchimp_last_synced_at"
    t.text "mailchimp_result", size: :medium
    t.boolean "mailchimp_include_additional_emails", default: false
    t.index ["group_id"], name: "index_mailing_lists_on_group_id"
  end

  create_table "message_recipients", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "message_id", null: false
    t.string "state", null: false
    t.string "target"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id"], name: "index_message_recipients_on_message_id"
    t.index ["person_id"], name: "index_message_recipients_on_person_id"
  end

  create_table "messages", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "type", null: false
    t.integer "recipients_source_id"
    t.string "recipients_source_type"
    t.text "body"
    t.string "subject"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "printed_at"
  end

  create_table "notes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "subject_id", null: false
    t.integer "author_id", null: false
    t.text "text", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "subject_type"
    t.index ["subject_id"], name: "index_notes_on_subject_id"
  end

  create_table "oauth_access_grants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", size: :medium, null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "fk_rails_b4b53e07b8"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "fk_rails_732cb83ab7"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", size: :medium, null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "fk_rails_77114b3b09"
  end

  create_table "payment_reminder_configs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "invoice_config_id", null: false
    t.string "title", null: false
    t.string "text", null: false
    t.integer "due_days", null: false
    t.integer "level", null: false
    t.index ["invoice_config_id"], name: "index_payment_reminder_configs_on_invoice_config_id"
  end

  create_table "payment_reminders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.date "due_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "text"
    t.integer "level"
    t.index ["invoice_id"], name: "index_payment_reminders_on_invoice_id"
  end

  create_table "payments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "received_at", null: false
    t.string "reference"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "people", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "company_name"
    t.string "nickname"
    t.boolean "company", default: false, null: false
    t.string "email"
    t.text "address", size: :medium
    t.string "zip_code"
    t.string "town"
    t.string "country"
    t.string "gender", limit: 1
    t.date "birthday"
    t.text "additional_information", size: :medium
    t.boolean "contact_data_visible", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "picture"
    t.integer "last_label_format_id"
    t.integer "creator_id"
    t.integer "updater_id"
    t.integer "primary_group_id"
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at"
    t.string "authentication_token"
    t.boolean "show_global_label_formats", default: true, null: false
    t.string "household_key"
    t.string "event_feed_token"
    t.string "unlock_token"
    t.index ["authentication_token"], name: "index_people_on_authentication_token"
    t.index ["email"], name: "index_people_on_email", unique: true
    t.index ["event_feed_token"], name: "index_people_on_event_feed_token", unique: true
    t.index ["household_key"], name: "index_people_on_household_key"
    t.index ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_people_on_unlock_token", unique: true
  end

  create_table "people_filters", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.integer "group_id"
    t.string "group_type"
    t.text "filter_chain", size: :medium
    t.string "range", default: "deep"
    t.timestamp "created_at"
    t.timestamp "updated_at"
    t.index ["group_id", "group_type"], name: "index_people_filters_on_group_id_and_group_type"
  end

  create_table "people_relations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "head_id", null: false
    t.integer "tail_id", null: false
    t.string "kind", null: false
    t.index ["head_id"], name: "index_people_relations_on_head_id"
    t.index ["tail_id"], name: "index_people_relations_on_tail_id"
  end

  create_table "person_add_request_ignored_approvers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "person_id", null: false
    t.index ["group_id", "person_id"], name: "person_add_request_ignored_approvers_index", unique: true
  end

  create_table "person_add_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "requester_id", null: false
    t.string "type", null: false
    t.integer "body_id", null: false
    t.string "role_type"
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["person_id"], name: "index_person_add_requests_on_person_id"
    t.index ["type", "body_id"], name: "index_person_add_requests_on_type_and_body_id"
  end

  create_table "person_duplicates", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "person_1_id", null: false
    t.integer "person_2_id", null: false
    t.boolean "ignore", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["person_1_id", "person_2_id"], name: "index_person_duplicates_on_person_1_id_and_person_2_id", unique: true
  end

  create_table "phone_numbers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "contactable_type", null: false
    t.integer "contactable_id", null: false
    t.string "number", null: false
    t.string "label"
    t.boolean "public", default: true, null: false
    t.index ["contactable_id", "contactable_type"], name: "index_phone_numbers_on_contactable_id_and_contactable_type"
  end

  create_table "qualification_kind_translations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "qualification_kind_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "label", null: false
    t.text "description", size: :medium
    t.index ["locale"], name: "index_qualification_kind_translations_on_locale"
    t.index ["qualification_kind_id"], name: "index_qualification_kind_translations_on_qualification_kind_id"
  end

  create_table "qualification_kinds", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "validity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "reactivateable"
  end

  create_table "qualifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "qualification_kind_id", null: false
    t.date "start_at", null: false
    t.date "finish_at"
    t.string "origin"
    t.index ["person_id"], name: "index_qualifications_on_person_id"
    t.index ["qualification_kind_id"], name: "index_qualifications_on_qualification_kind_id"
  end

  create_table "related_role_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "relation_id"
    t.string "role_type", null: false
    t.string "relation_type"
    t.index ["relation_id", "relation_type"], name: "index_related_role_types_on_relation_id_and_relation_type"
    t.index ["role_type"], name: "index_related_role_types_on_role_type"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "group_id", null: false
    t.string "type", null: false
    t.string "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["person_id", "group_id"], name: "index_roles_on_person_id_and_group_id"
    t.index ["type"], name: "index_roles_on_type"
  end

  create_table "service_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "layer_group_id", null: false
    t.string "name", null: false
    t.text "description", size: :medium
    t.string "token", null: false
    t.datetime "last_access"
    t.boolean "people", default: false
    t.boolean "people_below", default: false
    t.boolean "groups", default: false
    t.boolean "events", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "invoices", default: false, null: false
    t.boolean "event_participations", default: false, null: false
    t.boolean "mailing_lists", default: false, null: false
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.string "target_type", null: false
    t.integer "target_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["target_type", "target_id", "var"], name: "index_settings_on_target_type_and_target_id_and_var", unique: true
    t.index ["target_type", "target_id"], name: "index_settings_on_target_type_and_target_id"
  end

  create_table "social_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "contactable_type", null: false
    t.integer "contactable_id", null: false
    t.string "name", null: false
    t.string "label"
    t.boolean "public", default: true, null: false
    t.index ["contactable_id", "contactable_type"], name: "index_social_accounts_on_contactable_id_and_contactable_type"
  end

  create_table "subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "mailing_list_id", null: false
    t.string "subscriber_type", null: false
    t.integer "subscriber_id", null: false
    t.boolean "excluded", default: false, null: false
    t.index ["mailing_list_id"], name: "index_subscriptions_on_mailing_list_id"
    t.index ["subscriber_id", "subscriber_type"], name: "index_subscriptions_on_subscriber_id_and_subscriber_type"
  end

  create_table "table_displays", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "type", null: false
    t.integer "person_id", null: false
    t.text "selected", size: :medium
    t.index ["person_id", "type"], name: "index_table_displays_on_person_id_and_type", unique: true
  end

  create_table "taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "hitobito_tooltip"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
  end

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :medium
    t.text "object_changes", size: :medium
    t.string "main_type"
    t.integer "main_id"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["main_id", "main_type"], name: "index_versions_on_main_id_and_main_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
end
