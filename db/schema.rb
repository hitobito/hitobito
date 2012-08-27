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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120822130340) do

  create_table "groups", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "name",                       :null => false
    t.string   "short_name", :limit => 31
    t.string   "type",                       :null => false
    t.string   "email"
    t.string   "address",    :limit => 1024
    t.integer  "zip_code"
    t.string   "town"
    t.string   "country"
    t.integer  "contact_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.datetime "deleted_at"
    t.index ["parent_id"], :name => "index_groups_on_parent_id"
    t.index ["lft", "rgt"], :name => "index_groups_on_lft_and_rgt"
  end

  create_table "people", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "nickname"
    t.string   "email"
    t.string   "password"
    t.string   "address",                :limit => 1024
    t.integer  "zip_code"
    t.string   "town"
    t.string   "country"
    t.string   "gender",                 :limit => 1
    t.date     "birthday"
    t.text     "additional_information"
    t.boolean  "contact_data_visible",                   :default => false, :null => false
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
  end

  create_table "phone_numbers", :force => true do |t|
    t.integer "contactable_id",                     :null => false
    t.string  "contactable_type",                   :null => false
    t.string  "number",                             :null => false
    t.string  "label"
    t.boolean "public",           :default => true, :null => false
    t.index ["contactable_id", "contactable_type"], :name => "index_phone_numbers_on_contactable_id_and_contactable_type"
  end

  create_table "roles", :force => true do |t|
    t.integer  "person_id",  :null => false
    t.integer  "group_id",   :null => false
    t.string   "type",       :null => false
    t.string   "label"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "deleted_at"
    t.index ["person_id", "group_id"], :name => "index_roles_on_person_id_and_group_id"
  end

  create_table "social_accounts", :force => true do |t|
    t.integer "contactable_id",                     :null => false
    t.string  "contactable_type",                   :null => false
    t.string  "name",                               :null => false
    t.string  "label"
    t.boolean "public",           :default => true, :null => false
    t.index ["contactable_id", "contactable_type"], :name => "index_social_accounts_on_contactable_id_and_contactable_type"
  end

end
