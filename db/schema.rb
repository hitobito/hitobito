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

ActiveRecord::Schema.define(version: 20150706123121) do

  create_table "additional_emails", force: true do |t|
    t.integer "contactable_id",                  null: false
    t.string  "contactable_type",                null: false
    t.string  "email",                           null: false
    t.string  "label"
    t.boolean "public",           default: true, null: false
    t.boolean "mailings",         default: true, null: false
    t.index ["contactable_id", "contactable_type"], :name => "index_additional_emails_on_contactable_id_and_contactable_type"
  end

  create_table "custom_content_translations", force: true do |t|
    t.integer  "custom_content_id", null: false
    t.string   "locale",            null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label",             null: false
    t.string   "subject"
    t.text     "body"
    t.index ["custom_content_id"], :name => "index_custom_content_translations_on_custom_content_id"
    t.index ["locale"], :name => "index_custom_content_translations_on_locale"
  end

  create_table "custom_contents", force: true do |t|
    t.string "key",                   null: false
    t.string "placeholders_required"
    t.string "placeholders_optional"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], :name => "delayed_jobs_priority"
  end

  create_table "event_answers", force: true do |t|
    t.integer "participation_id", null: false
    t.integer "question_id",      null: false
    t.string  "answer"
    t.index ["participation_id", "question_id"], :name => "index_event_answers_on_participation_id_and_question_id", :unique => true
  end

  create_table "event_applications", force: true do |t|
    t.integer "priority_1_id",                 null: false
    t.integer "priority_2_id"
    t.integer "priority_3_id"
    t.boolean "approved",      default: false, null: false
    t.boolean "rejected",      default: false, null: false
    t.boolean "waiting_list",  default: false, null: false
  end

  create_table "event_dates", force: true do |t|
    t.integer  "event_id",  null: false
    t.string   "label"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.string   "location"
    t.index ["event_id", "start_at"], :name => "index_event_dates_on_event_id_and_start_at"
    t.index ["event_id"], :name => "index_event_dates_on_event_id"
  end

  create_table "event_kind_qualification_kinds", force: true do |t|
    t.integer "event_kind_id",         null: false
    t.integer "qualification_kind_id", null: false
    t.string  "category",              null: false
    t.string  "role",                  null: false
    t.index ["category"], :name => "index_event_kind_qualification_kinds_on_category"
    t.index ["role"], :name => "index_event_kind_qualification_kinds_on_role"
  end

  create_table "event_kind_translations", force: true do |t|
    t.integer  "event_kind_id", null: false
    t.string   "locale",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label",         null: false
    t.string   "short_name"
    t.index ["event_kind_id"], :name => "index_event_kind_translations_on_event_kind_id"
    t.index ["locale"], :name => "index_event_kind_translations_on_locale"
  end

  create_table "event_kinds", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "minimum_age"
    t.text     "general_information"
    t.text     "application_conditions"
  end

  create_table "event_participations", force: true do |t|
    t.integer  "event_id",                               null: false
    t.integer  "person_id",                              null: false
    t.text     "additional_information"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                 default: false, null: false
    t.integer  "application_id"
    t.boolean  "qualified"
    t.index ["event_id", "person_id"], :name => "index_event_participations_on_event_id_and_person_id", :unique => true
    t.index ["event_id"], :name => "index_event_participations_on_event_id"
    t.index ["person_id"], :name => "index_event_participations_on_person_id"
  end

  create_table "event_questions", force: true do |t|
    t.integer "event_id"
    t.string  "question"
    t.string  "choices"
    t.boolean "multiple_choices", default: false
    t.boolean "required"
    t.index ["event_id"], :name => "index_event_questions_on_event_id"
  end

  create_table "event_roles", force: true do |t|
    t.string  "type",             null: false
    t.integer "participation_id", null: false
    t.string  "label"
    t.index ["participation_id"], :name => "index_event_roles_on_participation_id"
    t.index ["type"], :name => "index_event_roles_on_type"
  end

  create_table "events", force: true do |t|
    t.string   "type"
    t.string   "name",                                                   null: false
    t.string   "number"
    t.string   "motto"
    t.string   "cost"
    t.integer  "maximum_participants"
    t.integer  "contact_id"
    t.text     "description"
    t.text     "location"
    t.date     "application_opening_at"
    t.date     "application_closing_at"
    t.text     "application_conditions"
    t.integer  "kind_id"
    t.string   "state",                       limit: 60
    t.boolean  "priorization",                           default: false, null: false
    t.boolean  "requires_approval",                      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "participant_count",                      default: 0
    t.integer  "application_contact_id"
    t.boolean  "external_applications",                  default: false
    t.integer  "applicant_count",                        default: 0
    t.integer  "teamer_count",                           default: 0
    t.boolean  "signature"
    t.boolean  "signature_confirmation"
    t.string   "signature_confirmation_text"
    t.index ["kind_id"], :name => "index_events_on_kind_id"
  end

  create_table "events_groups", id: false, force: true do |t|
    t.integer "event_id"
    t.integer "group_id"
    t.index ["event_id", "group_id"], :name => "index_events_groups_on_event_id_and_group_id", :unique => true
  end

  create_table "groups", force: true do |t|
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "name",                        null: false
    t.string   "short_name",     limit: 31
    t.string   "type",                        null: false
    t.string   "email"
    t.string   "address",        limit: 1024
    t.integer  "zip_code"
    t.string   "town"
    t.string   "country"
    t.integer  "contact_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "layer_group_id"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "deleter_id"
    t.index ["layer_group_id"], :name => "index_groups_on_layer_group_id"
    t.index ["lft", "rgt"], :name => "index_groups_on_lft_and_rgt"
    t.index ["parent_id"], :name => "index_groups_on_parent_id"
  end

  create_table "label_format_translations", force: true do |t|
    t.integer  "label_format_id", null: false
    t.string   "locale",          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",            null: false
    t.index ["label_format_id"], :name => "index_label_format_translations_on_label_format_id"
    t.index ["locale"], :name => "index_label_format_translations_on_locale"
  end

  create_table "label_formats", force: true do |t|
    t.string  "page_size",        default: "A4",  null: false
    t.boolean "landscape",        default: false, null: false
    t.float   "font_size",        default: 11.0,  null: false
    t.float   "width",                            null: false
    t.float   "height",                           null: false
    t.integer "count_horizontal",                 null: false
    t.integer "count_vertical",                   null: false
    t.float   "padding_top",                      null: false
    t.float   "padding_left",                     null: false
  end

  create_table "mailing_lists", force: true do |t|
    t.string  "name",                                 null: false
    t.integer "group_id",                             null: false
    t.text    "description"
    t.string  "publisher"
    t.string  "mail_name"
    t.string  "additional_sender"
    t.boolean "subscribable",         default: false, null: false
    t.boolean "subscribers_may_post", default: false, null: false
    t.boolean "anyone_may_post",      default: false, null: false
    t.index ["group_id"], :name => "index_mailing_lists_on_group_id"
  end

  create_table "people", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "nickname"
    t.boolean  "company",                             default: false, null: false
    t.string   "email"
    t.string   "address",                limit: 1024
    t.string   "zip_code"
    t.string   "town"
    t.string   "country"
    t.string   "gender",                 limit: 1
    t.date     "birthday"
    t.text     "additional_information"
    t.boolean  "contact_data_visible",                default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "picture"
    t.integer  "last_label_format_id"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "primary_group_id"
    t.integer  "failed_attempts",                     default: 0
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.index ["authentication_token"], :name => "index_people_on_authentication_token"
    t.index ["email"], :name => "index_people_on_email", :unique => true
    t.index ["reset_password_token"], :name => "index_people_on_reset_password_token", :unique => true
  end

  create_table "people_filters", force: true do |t|
    t.string  "name",       null: false
    t.integer "group_id"
    t.string  "group_type"
    t.index ["group_id", "group_type"], :name => "index_people_filters_on_group_id_and_group_type"
  end

  create_table "people_relations", force: true do |t|
    t.integer "head_id", null: false
    t.integer "tail_id", null: false
    t.string  "kind",    null: false
    t.index ["head_id"], :name => "index_people_relations_on_head_id"
    t.index ["tail_id"], :name => "index_people_relations_on_tail_id"
  end

  create_table "phone_numbers", force: true do |t|
    t.integer "contactable_id",                  null: false
    t.string  "contactable_type",                null: false
    t.string  "number",                          null: false
    t.string  "label"
    t.boolean "public",           default: true, null: false
    t.index ["contactable_id", "contactable_type"], :name => "index_phone_numbers_on_contactable_id_and_contactable_type"
  end

  create_table "qualification_kind_translations", force: true do |t|
    t.integer  "qualification_kind_id",              null: false
    t.string   "locale",                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label",                              null: false
    t.string   "description",           limit: 1023
    t.index ["locale"], :name => "index_qualification_kind_translations_on_locale"
    t.index ["qualification_kind_id"], :name => "index_qualification_kind_translations_on_qualification_kind_id"
  end

  create_table "qualification_kinds", force: true do |t|
    t.integer  "validity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "reactivateable"
  end

  create_table "qualifications", force: true do |t|
    t.integer "person_id",             null: false
    t.integer "qualification_kind_id", null: false
    t.date    "start_at",              null: false
    t.date    "finish_at"
    t.string  "origin"
    t.index ["person_id"], :name => "index_qualifications_on_person_id"
    t.index ["qualification_kind_id"], :name => "index_qualifications_on_qualification_kind_id"
  end

  create_table "related_role_types", force: true do |t|
    t.integer "relation_id"
    t.string  "role_type",     null: false
    t.string  "relation_type"
    t.index ["relation_id", "relation_type"], :name => "index_related_role_types_on_relation_id_and_relation_type"
    t.index ["role_type"], :name => "index_related_role_types_on_role_type"
  end

  create_table "roles", force: true do |t|
    t.integer  "person_id",  null: false
    t.integer  "group_id",   null: false
    t.string   "type",       null: false
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["person_id", "group_id"], :name => "index_roles_on_person_id_and_group_id"
    t.index ["type"], :name => "index_roles_on_type"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], :name => "index_sessions_on_session_id"
    t.index ["updated_at"], :name => "index_sessions_on_updated_at"
  end

  create_table "social_accounts", force: true do |t|
    t.integer "contactable_id",                  null: false
    t.string  "contactable_type",                null: false
    t.string  "name",                            null: false
    t.string  "label"
    t.boolean "public",           default: true, null: false
    t.index ["contactable_id", "contactable_type"], :name => "index_social_accounts_on_contactable_id_and_contactable_type"
  end

  create_table "subscriptions", force: true do |t|
    t.integer "mailing_list_id",                 null: false
    t.integer "subscriber_id",                   null: false
    t.string  "subscriber_type",                 null: false
    t.boolean "excluded",        default: false, null: false
    t.index ["mailing_list_id"], :name => "index_subscriptions_on_mailing_list_id"
    t.index ["subscriber_id", "subscriber_type"], :name => "index_subscriptions_on_subscriber_id_and_subscriber_type"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.text     "object_changes"
    t.string   "main_type"
    t.integer  "main_id"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"
    t.index ["main_id", "main_type"], :name => "index_versions_on_main_id_and_main_type"
  end

end
