# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170529134942) do

  create_table "additional_emails", force: :cascade do |t|
    t.integer "contactable_id",   limit: 4,                  null: false
    t.string  "contactable_type", limit: 255,                null: false
    t.string  "email",            limit: 255,                null: false
    t.string  "label",            limit: 255
    t.boolean "public",                       default: true, null: false
    t.boolean "mailings",                     default: true, null: false
  end

  add_index "additional_emails", ["contactable_id", "contactable_type"], name: "index_additional_emails_on_contactable_id_and_contactable_type"

  create_table "custom_content_translations", force: :cascade do |t|
    t.integer  "custom_content_id", limit: 4,     null: false
    t.string   "locale",            limit: 255,   null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "label",             limit: 255,   null: false
    t.string   "subject",           limit: 255
    t.text     "body",              limit: 65535
  end

  add_index "custom_content_translations", ["custom_content_id"], name: "index_custom_content_translations_on_custom_content_id"
  add_index "custom_content_translations", ["locale"], name: "index_custom_content_translations_on_locale"

  create_table "custom_contents", force: :cascade do |t|
    t.string "key",                   limit: 255, null: false
    t.string "placeholders_required", limit: 255
    t.string "placeholders_optional", limit: 255
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "event_answers", force: :cascade do |t|
    t.integer "participation_id", limit: 4,   null: false
    t.integer "question_id",      limit: 4,   null: false
    t.string  "answer",           limit: 255
  end

  add_index "event_answers", ["participation_id", "question_id"], name: "index_event_answers_on_participation_id_and_question_id", unique: true

  create_table "event_applications", force: :cascade do |t|
    t.integer "priority_1_id",        limit: 4,                     null: false
    t.integer "priority_2_id",        limit: 4
    t.integer "priority_3_id",        limit: 4
    t.boolean "approved",                           default: false, null: false
    t.boolean "rejected",                           default: false, null: false
    t.boolean "waiting_list",                       default: false, null: false
    t.text    "waiting_list_comment", limit: 65535
  end

  create_table "event_attachments", force: :cascade do |t|
    t.integer "event_id", limit: 4,   null: false
    t.string  "file",     limit: 255, null: false
  end

  add_index "event_attachments", ["event_id"], name: "index_event_attachments_on_event_id"

  create_table "event_dates", force: :cascade do |t|
    t.integer  "event_id",  limit: 4,   null: false
    t.string   "label",     limit: 255
    t.datetime "start_at"
    t.datetime "finish_at"
    t.string   "location",  limit: 255
  end

  add_index "event_dates", ["event_id", "start_at"], name: "index_event_dates_on_event_id_and_start_at"
  add_index "event_dates", ["event_id"], name: "index_event_dates_on_event_id"

  create_table "event_kind_qualification_kinds", force: :cascade do |t|
    t.integer "event_kind_id",         limit: 4,   null: false
    t.integer "qualification_kind_id", limit: 4,   null: false
    t.string  "category",              limit: 255, null: false
    t.string  "role",                  limit: 255, null: false
  end

  add_index "event_kind_qualification_kinds", ["category"], name: "index_event_kind_qualification_kinds_on_category"
  add_index "event_kind_qualification_kinds", ["role"], name: "index_event_kind_qualification_kinds_on_role"

  create_table "event_kind_translations", force: :cascade do |t|
    t.integer  "event_kind_id",          limit: 4,     null: false
    t.string   "locale",                 limit: 255,   null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "label",                  limit: 255,   null: false
    t.string   "short_name",             limit: 255
    t.text     "general_information",    limit: 65535
    t.text     "application_conditions", limit: 65535
  end

  add_index "event_kind_translations", ["event_kind_id"], name: "index_event_kind_translations_on_event_kind_id"
  add_index "event_kind_translations", ["locale"], name: "index_event_kind_translations_on_locale"

  create_table "event_kinds", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "minimum_age", limit: 4
  end

  create_table "event_participations", force: :cascade do |t|
    t.integer  "event_id",               limit: 4,                     null: false
    t.integer  "person_id",              limit: 4,                     null: false
    t.text     "additional_information", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                               default: false, null: false
    t.integer  "application_id",         limit: 4
    t.boolean  "qualified"
  end

  add_index "event_participations", ["event_id", "person_id"], name: "index_event_participations_on_event_id_and_person_id", unique: true
  add_index "event_participations", ["event_id"], name: "index_event_participations_on_event_id"
  add_index "event_participations", ["person_id"], name: "index_event_participations_on_person_id"

  create_table "event_questions", force: :cascade do |t|
    t.integer "event_id",         limit: 4
    t.string  "question",         limit: 255
    t.string  "choices",          limit: 255
    t.boolean "multiple_choices",             default: false
    t.boolean "required"
  end

  add_index "event_questions", ["event_id"], name: "index_event_questions_on_event_id"

  create_table "event_roles", force: :cascade do |t|
    t.string  "type",             limit: 255, null: false
    t.integer "participation_id", limit: 4,   null: false
    t.string  "label",            limit: 255
  end

  add_index "event_roles", ["participation_id"], name: "index_event_roles_on_participation_id"
  add_index "event_roles", ["type"], name: "index_event_roles_on_type"

  create_table "events", force: :cascade do |t|
    t.string   "type",                        limit: 255
    t.string   "name",                        limit: 255,                   null: false
    t.string   "number",                      limit: 255
    t.string   "motto",                       limit: 255
    t.string   "cost",                        limit: 255
    t.integer  "maximum_participants",        limit: 4
    t.integer  "contact_id",                  limit: 4
    t.text     "description",                 limit: 65535
    t.text     "location",                    limit: 65535
    t.date     "application_opening_at"
    t.date     "application_closing_at"
    t.text     "application_conditions",      limit: 65535
    t.integer  "kind_id",                     limit: 4
    t.string   "state",                       limit: 60
    t.boolean  "priorization",                              default: false, null: false
    t.boolean  "requires_approval",                         default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "participant_count",           limit: 4,     default: 0
    t.integer  "application_contact_id",      limit: 4
    t.boolean  "external_applications",                     default: false
    t.integer  "applicant_count",             limit: 4,     default: 0
    t.integer  "teamer_count",                limit: 4,     default: 0
    t.boolean  "signature"
    t.boolean  "signature_confirmation"
    t.string   "signature_confirmation_text", limit: 255
    t.integer  "creator_id",                  limit: 4
    t.integer  "updater_id",                  limit: 4
    t.boolean  "applications_cancelable",                   default: false, null: false
  end

  add_index "events", ["kind_id"], name: "index_events_on_kind_id"

  create_table "events_groups", id: false, force: :cascade do |t|
    t.integer "event_id", limit: 4
    t.integer "group_id", limit: 4
  end

  add_index "events_groups", ["event_id", "group_id"], name: "index_events_groups_on_event_id_and_group_id", unique: true

  create_table "groups", force: :cascade do |t|
    t.integer  "parent_id",                   limit: 4
    t.integer  "lft",                         limit: 4
    t.integer  "rgt",                         limit: 4
    t.string   "name",                        limit: 255,                  null: false
    t.string   "short_name",                  limit: 31
    t.string   "type",                        limit: 255,                  null: false
    t.string   "email",                       limit: 255
    t.string   "address",                     limit: 1024
    t.integer  "zip_code",                    limit: 4
    t.string   "town",                        limit: 255
    t.string   "country",                     limit: 255
    t.integer  "contact_id",                  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "layer_group_id",              limit: 4
    t.integer  "creator_id",                  limit: 4
    t.integer  "updater_id",                  limit: 4
    t.integer  "deleter_id",                  limit: 4
    t.boolean  "require_person_add_requests",              default: false, null: false
  end

  add_index "groups", ["layer_group_id"], name: "index_groups_on_layer_group_id"
  add_index "groups", ["lft", "rgt"], name: "index_groups_on_lft_and_rgt"
  add_index "groups", ["parent_id"], name: "index_groups_on_parent_id"

  create_table "label_format_translations", force: :cascade do |t|
    t.integer  "label_format_id", limit: 4,   null: false
    t.string   "locale",          limit: 255, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "name",            limit: 255, null: false
  end

  add_index "label_format_translations", ["label_format_id"], name: "index_label_format_translations_on_label_format_id"
  add_index "label_format_translations", ["locale"], name: "index_label_format_translations_on_locale"

  create_table "label_formats", force: :cascade do |t|
    t.string  "page_size",        limit: 255, default: "A4",  null: false
    t.boolean "landscape",                    default: false, null: false
    t.float   "font_size",        limit: 24,  default: 11.0,  null: false
    t.float   "width",            limit: 24,                  null: false
    t.float   "height",           limit: 24,                  null: false
    t.integer "count_horizontal", limit: 4,                   null: false
    t.integer "count_vertical",   limit: 4,                   null: false
    t.float   "padding_top",      limit: 24,                  null: false
    t.float   "padding_left",     limit: 24,                  null: false
    t.integer "person_id",        limit: 4
    t.boolean "nickname",                     default: false, null: false
    t.string  "pp_post",          limit: 23
  end

  create_table "locations", force: :cascade do |t|
    t.string "name",     limit: 255, null: false
    t.string "canton",   limit: 2,   null: false
    t.string "zip_code", limit: 255, null: false
  end

  add_index "locations", ["zip_code", "canton", "name"], name: "index_locations_on_zip_code_and_canton_and_name", unique: true

  create_table "mailing_lists", force: :cascade do |t|
    t.string  "name",                 limit: 255,                   null: false
    t.integer "group_id",             limit: 4,                     null: false
    t.text    "description",          limit: 65535
    t.string  "publisher",            limit: 255
    t.string  "mail_name",            limit: 255
    t.string  "additional_sender",    limit: 255
    t.boolean "subscribable",                       default: false, null: false
    t.boolean "subscribers_may_post",               default: false, null: false
    t.boolean "anyone_may_post",                    default: false, null: false
  end

  add_index "mailing_lists", ["group_id"], name: "index_mailing_lists_on_group_id"

  create_table "notes", force: :cascade do |t|
    t.integer  "subject_id",   limit: 4,     null: false
    t.integer  "author_id",    limit: 4,     null: false
    t.text     "text",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject_type", limit: 255
  end

  add_index "notes", ["subject_id"], name: "index_notes_on_subject_id"

  create_table "people", force: :cascade do |t|
    t.string   "first_name",                limit: 255
    t.string   "last_name",                 limit: 255
    t.string   "company_name",              limit: 255
    t.string   "nickname",                  limit: 255
    t.boolean  "company",                                 default: false, null: false
    t.string   "email",                     limit: 255
    t.string   "address",                   limit: 1024
    t.string   "zip_code",                  limit: 255
    t.string   "town",                      limit: 255
    t.string   "country",                   limit: 255
    t.string   "gender",                    limit: 1
    t.date     "birthday"
    t.text     "additional_information",    limit: 65535
    t.boolean  "contact_data_visible",                    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password",        limit: 255
    t.string   "reset_password_token",      limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             limit: 4,     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",        limit: 255
    t.string   "last_sign_in_ip",           limit: 255
    t.string   "picture",                   limit: 255
    t.integer  "last_label_format_id",      limit: 4
    t.integer  "creator_id",                limit: 4
    t.integer  "updater_id",                limit: 4
    t.integer  "primary_group_id",          limit: 4
    t.integer  "failed_attempts",           limit: 4,     default: 0
    t.datetime "locked_at"
    t.string   "authentication_token",      limit: 255
    t.boolean  "show_global_label_formats",               default: true,  null: false
  end

  add_index "people", ["authentication_token"], name: "index_people_on_authentication_token"
  add_index "people", ["email"], name: "index_people_on_email", unique: true
  add_index "people", ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true

  create_table "people_filters", force: :cascade do |t|
    t.string  "name",       limit: 255, null: false
    t.integer "group_id",   limit: 4
    t.string  "group_type", limit: 255
  end

  add_index "people_filters", ["group_id", "group_type"], name: "index_people_filters_on_group_id_and_group_type"

  create_table "people_relations", force: :cascade do |t|
    t.integer "head_id", limit: 4,   null: false
    t.integer "tail_id", limit: 4,   null: false
    t.string  "kind",    limit: 255, null: false
  end

  add_index "people_relations", ["head_id"], name: "index_people_relations_on_head_id"
  add_index "people_relations", ["tail_id"], name: "index_people_relations_on_tail_id"

  create_table "person_add_request_ignored_approvers", force: :cascade do |t|
    t.integer "group_id",  limit: 4, null: false
    t.integer "person_id", limit: 4, null: false
  end

  add_index "person_add_request_ignored_approvers", ["group_id", "person_id"], name: "person_add_request_ignored_approvers_index", unique: true

  create_table "person_add_requests", force: :cascade do |t|
    t.integer  "person_id",    limit: 4,   null: false
    t.integer  "requester_id", limit: 4,   null: false
    t.string   "type",         limit: 255, null: false
    t.integer  "body_id",      limit: 4,   null: false
    t.string   "role_type",    limit: 255
    t.datetime "created_at",               null: false
  end

  add_index "person_add_requests", ["person_id"], name: "index_person_add_requests_on_person_id"
  add_index "person_add_requests", ["type", "body_id"], name: "index_person_add_requests_on_type_and_body_id"

  create_table "phone_numbers", force: :cascade do |t|
    t.integer "contactable_id",   limit: 4,                  null: false
    t.string  "contactable_type", limit: 255,                null: false
    t.string  "number",           limit: 255,                null: false
    t.string  "label",            limit: 255
    t.boolean "public",                       default: true, null: false
  end

  add_index "phone_numbers", ["contactable_id", "contactable_type"], name: "index_phone_numbers_on_contactable_id_and_contactable_type"

  create_table "qualification_kind_translations", force: :cascade do |t|
    t.integer  "qualification_kind_id", limit: 4,    null: false
    t.string   "locale",                limit: 255,  null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "label",                 limit: 255,  null: false
    t.string   "description",           limit: 1023
  end

  add_index "qualification_kind_translations", ["locale"], name: "index_qualification_kind_translations_on_locale"
  add_index "qualification_kind_translations", ["qualification_kind_id"], name: "index_qualification_kind_translations_on_qualification_kind_id"

  create_table "qualification_kinds", force: :cascade do |t|
    t.integer  "validity",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "reactivateable", limit: 4
  end

  create_table "qualifications", force: :cascade do |t|
    t.integer "person_id",             limit: 4,   null: false
    t.integer "qualification_kind_id", limit: 4,   null: false
    t.date    "start_at",                          null: false
    t.date    "finish_at"
    t.string  "origin",                limit: 255
  end

  add_index "qualifications", ["person_id"], name: "index_qualifications_on_person_id"
  add_index "qualifications", ["qualification_kind_id"], name: "index_qualifications_on_qualification_kind_id"

  create_table "related_role_types", force: :cascade do |t|
    t.integer "relation_id",   limit: 4
    t.string  "role_type",     limit: 255, null: false
    t.string  "relation_type", limit: 255
  end

  add_index "related_role_types", ["relation_id", "relation_type"], name: "index_related_role_types_on_relation_id_and_relation_type"
  add_index "related_role_types", ["role_type"], name: "index_related_role_types_on_role_type"

  create_table "roles", force: :cascade do |t|
    t.integer  "person_id",  limit: 4,   null: false
    t.integer  "group_id",   limit: 4,   null: false
    t.string   "type",       limit: 255, null: false
    t.string   "label",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "roles", ["person_id", "group_id"], name: "index_roles_on_person_id_and_group_id"
  add_index "roles", ["type"], name: "index_roles_on_type"

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "social_accounts", force: :cascade do |t|
    t.integer "contactable_id",   limit: 4,                  null: false
    t.string  "contactable_type", limit: 255,                null: false
    t.string  "name",             limit: 255,                null: false
    t.string  "label",            limit: 255
    t.boolean "public",                       default: true, null: false
  end

  add_index "social_accounts", ["contactable_id", "contactable_type"], name: "index_social_accounts_on_contactable_id_and_contactable_type"

  create_table "subscriptions", force: :cascade do |t|
    t.integer "mailing_list_id", limit: 4,                   null: false
    t.integer "subscriber_id",   limit: 4,                   null: false
    t.string  "subscriber_type", limit: 255,                 null: false
    t.boolean "excluded",                    default: false, null: false
  end

  add_index "subscriptions", ["mailing_list_id"], name: "index_subscriptions_on_mailing_list_id"
  add_index "subscriptions", ["subscriber_id", "subscriber_type"], name: "index_subscriptions_on_subscriber_id_and_subscriber_type"

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      limit: 255,   null: false
    t.integer  "item_id",        limit: 4,     null: false
    t.string   "event",          limit: 255,   null: false
    t.string   "whodunnit",      limit: 255
    t.text     "object",         limit: 65535
    t.text     "object_changes", limit: 65535
    t.string   "main_type",      limit: 255
    t.integer  "main_id",        limit: 4
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  add_index "versions", ["main_id", "main_type"], name: "index_versions_on_main_id_and_main_type"

end
