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

ActiveRecord::Schema.define(version: 2021_05_08_173347) do

  create_table "cloud_computing_accesses", force: :cascade do |t|
    t.date "finish_date"
    t.integer "user_id"
    t.integer "allowed_by_id"
    t.string "for_type"
    t.integer "for_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "blocked", default: false
    t.index ["allowed_by_id"], name: "index_cloud_computing_accesses_on_allowed_by_id"
    t.index ["for_type", "for_id"], name: "index_cloud_computing_accesses_on_for_type_and_for_id"
    t.index ["user_id"], name: "index_cloud_computing_accesses_on_user_id"
  end

  create_table "cloud_computing_api_logs", force: :cascade do |t|
    t.integer "item_id"
    t.text "log"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource"
    t.boolean "success"
    t.string "code"
    t.index ["item_id"], name: "index_cloud_computing_api_logs_on_item_id"
  end

  create_table "cloud_computing_cloud_attributes", force: :cascade do |t|
    t.integer "cloud_id"
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cloud_id"], name: "index_cloud_computing_cloud_attributes_on_cloud_id"
  end

  create_table "cloud_computing_clouds", force: :cascade do |t|
    t.string "kind"
    t.string "name_en"
    t.string "name_ru"
    t.text "description_en"
    t.text "description_ru"
    t.text "remote_host"
    t.text "remote_private_key"
    t.integer "remote_port"
    t.string "remote_path"
    t.string "remote_user"
    t.text "remote_password"
    t.text "remote_command"
    t.string "remote_proxy_host"
    t.integer "remote_proxy_port"
    t.boolean "remote_use_ssl"
    t.text "octo_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cloud_computing_conditions", force: :cascade do |t|
    t.string "from_type"
    t.integer "from_id"
    t.string "to_type"
    t.integer "to_id"
    t.string "from_multiplicity"
    t.string "to_multiplicity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_type", "from_id"], name: "index_cloud_computing_conditions_on_from_type_and_from_id"
    t.index ["to_type", "to_id"], name: "index_cloud_computing_conditions_on_to_type_and_to_id"
  end

  create_table "cloud_computing_item_links", force: :cascade do |t|
    t.integer "from_id"
    t.integer "to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_id"], name: "index_cloud_computing_item_links_on_from_id"
    t.index ["to_id"], name: "index_cloud_computing_item_links_on_to_id"
  end

  create_table "cloud_computing_items", force: :cascade do |t|
    t.integer "template_id"
    t.integer "item_id"
    t.string "holder_type"
    t.integer "holder_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holder_type", "holder_id"], name: "index_cloud_computing_items_on_holder_type_and_holder_id"
    t.index ["item_id"], name: "index_cloud_computing_items_on_item_id"
    t.index ["template_id"], name: "index_cloud_computing_items_on_template_id"
  end

  create_table "cloud_computing_requests", force: :cascade do |t|
    t.text "comment"
    t.text "admin_comment"
    t.date "finish_date"
    t.integer "created_by_id"
    t.integer "access_id"
    t.string "for_type"
    t.integer "for_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_id"], name: "index_cloud_computing_requests_on_access_id"
    t.index ["created_by_id"], name: "index_cloud_computing_requests_on_created_by_id"
    t.index ["for_type", "for_id"], name: "index_cloud_computing_requests_on_for_type_and_for_id"
  end

  create_table "cloud_computing_resource_items", force: :cascade do |t|
    t.integer "resource_id"
    t.integer "item_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_cloud_computing_resource_items_on_item_id"
    t.index ["resource_id"], name: "index_cloud_computing_resource_items_on_resource_id"
  end

  create_table "cloud_computing_resource_kinds", force: :cascade do |t|
    t.string "name_ru"
    t.string "name_en"
    t.text "description_en"
    t.text "description_ru"
    t.string "help_en"
    t.string "help_ru"
    t.string "measurement_ru"
    t.string "measurement_en"
    t.string "identity"
    t.integer "content_type"
    t.integer "template_kind_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_kind_id"], name: "index_cloud_computing_resource_kinds_on_template_kind_id"
  end

  create_table "cloud_computing_resources", force: :cascade do |t|
    t.integer "resource_kind_id"
    t.integer "template_id"
    t.string "value"
    t.boolean "editable", default: false
    t.decimal "min"
    t.decimal "max"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_kind_id"], name: "index_cloud_computing_resources_on_resource_kind_id"
    t.index ["template_id"], name: "index_cloud_computing_resources_on_template_id"
  end

  create_table "cloud_computing_template_kinds", force: :cascade do |t|
    t.string "name_ru"
    t.string "name_en"
    t.text "description_ru"
    t.text "description_en"
    t.string "cloud_class"
    t.integer "parent_id"
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lft"], name: "index_cloud_computing_template_kinds_on_lft"
    t.index ["parent_id"], name: "index_cloud_computing_template_kinds_on_parent_id"
    t.index ["rgt"], name: "index_cloud_computing_template_kinds_on_rgt"
  end

  create_table "cloud_computing_templates", force: :cascade do |t|
    t.integer "template_kind_id"
    t.string "name_ru"
    t.string "name_en"
    t.text "description_ru"
    t.text "description_en"
    t.integer "identity"
    t.boolean "new_requests", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cloud_id"
    t.index ["cloud_id"], name: "index_cloud_computing_templates_on_cloud_id"
    t.index ["template_kind_id"], name: "index_cloud_computing_templates_on_template_kind_id"
  end

  create_table "cloud_computing_virtual_machine_actions", force: :cascade do |t|
    t.integer "virtual_machine_id"
    t.string "name_ru"
    t.string "name_en"
    t.text "description_ru"
    t.text "description_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["virtual_machine_id"], name: "virtual_machine_index"
  end

  create_table "cloud_computing_virtual_machines", force: :cascade do |t|
    t.integer "identity"
    t.integer "item_id"
    t.string "inner_address"
    t.string "internet_address"
    t.string "state"
    t.string "lcm_state"
    t.datetime "last_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "human_state_ru"
    t.string "human_state_en"
    t.text "description_ru"
    t.text "description_en"
    t.index ["item_id"], name: "index_cloud_computing_virtual_machines_on_item_id"
  end

end
