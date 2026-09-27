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

ActiveRecord::Schema[7.1].define(version: 2026_09_27_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "approval_steps", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.integer "stage", null: false
    t.integer "decision", default: 0, null: false
    t.bigint "decided_by_id"
    t.datetime "decided_at"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decided_by_id"], name: "index_approval_steps_on_decided_by_id"
    t.index ["expense_id", "stage"], name: "index_approval_steps_on_expense_id_and_stage", unique: true
    t.index ["expense_id"], name: "index_approval_steps_on_expense_id"
    t.check_constraint "decision = ANY (ARRAY[0, 1, 2])", name: "approval_steps_decision_valid"
    t.check_constraint "stage = ANY (ARRAY[0, 1])", name: "approval_steps_stage_valid"
  end

  create_table "expense_audits", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.jsonb "changeset", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "created_at"], name: "index_expense_audits_on_expense_id_and_created_at"
    t.index ["expense_id"], name: "index_expense_audits_on_expense_id"
    t.index ["user_id"], name: "index_expense_audits_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "member_id", null: false
    t.integer "amount_cents", null: false
    t.string "description", null: false
    t.date "spent_on", null: false
    t.string "category", null: false
    t.integer "status", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_expenses_on_member_id"
    t.index ["team_id", "spent_on"], name: "index_expenses_on_team_id_and_spent_on"
    t.index ["team_id", "status"], name: "index_expenses_on_team_id_and_status"
    t.index ["team_id"], name: "index_expenses_on_team_id"
    t.check_constraint "amount_cents > 0", name: "expenses_amount_positive"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2, 3, 4, 5])", name: "expenses_status_valid"
  end

  create_table "external_transactions", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "expense_id"
    t.string "external_id", null: false
    t.integer "amount_cents", null: false
    t.string "description", null: false
    t.date "transacted_on", null: false
    t.integer "status", default: 0, null: false
    t.text "review_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_external_transactions_on_expense_id"
    t.index ["team_id", "external_id"], name: "index_external_transactions_on_team_id_and_external_id", unique: true
    t.index ["team_id", "status"], name: "index_external_transactions_on_team_id_and_status"
    t.index ["team_id"], name: "index_external_transactions_on_team_id"
    t.check_constraint "amount_cents > 0", name: "external_transactions_amount_positive"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2])", name: "external_transactions_status_valid"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_memberships_on_team_id"
    t.index ["user_id", "team_id"], name: "index_memberships_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "role = ANY (ARRAY[0, 1, 2, 3])", name: "memberships_role_valid"
  end

  create_table "reimbursements", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_reimbursements_on_expense_id", unique: true
    t.check_constraint "status = ANY (ARRAY[0, 1, 2, 3])", name: "reimbursements_status_valid"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "join_code", null: false
    t.index ["join_code"], name: "index_teams_on_join_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "approval_steps", "expenses"
  add_foreign_key "approval_steps", "users", column: "decided_by_id"
  add_foreign_key "expense_audits", "expenses"
  add_foreign_key "expense_audits", "users"
  add_foreign_key "expenses", "teams"
  add_foreign_key "expenses", "users", column: "member_id"
  add_foreign_key "external_transactions", "expenses"
  add_foreign_key "external_transactions", "teams"
  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "reimbursements", "expenses"
end
