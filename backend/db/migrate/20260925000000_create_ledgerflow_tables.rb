class CreateLedgerflowTables < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, null: false
        t.string :password_digest, null: false
        t.timestamps
      end
      add_index :users, :email, unique: true
    end

    unless table_exists?(:teams)
      create_table :teams do |t|
        t.string :name, null: false
        t.timestamps
      end
    end

    unless table_exists?(:memberships)
      create_table :memberships do |t|
        t.references :user, null: false, foreign_key: true
        t.references :team, null: false, foreign_key: true
        t.integer :role, null: false, default: 0
        t.timestamps
      end
      add_index :memberships, [:user_id, :team_id], unique: true
      add_check_constraint :memberships, "role IN (0, 1, 2, 3)", name: "memberships_role_valid"
    end

    unless table_exists?(:expenses)
      create_table :expenses do |t|
        t.references :team, null: false, foreign_key: true
        t.references :member, null: false, foreign_key: { to_table: :users }
        t.integer :amount_cents, null: false
        t.string :description, null: false
        t.date :spent_on, null: false
        t.string :category, null: false
        t.integer :status, null: false, default: 0
        t.integer :lock_version, null: false, default: 0
        t.datetime :deleted_at
        t.timestamps
      end
      add_index :expenses, [:team_id, :spent_on]
      add_index :expenses, [:team_id, :status]
      add_check_constraint :expenses, "amount_cents > 0", name: "expenses_amount_positive"
      add_check_constraint :expenses, "status IN (0, 1, 2, 3, 4, 5)", name: "expenses_status_valid"
    end

    unless table_exists?(:expense_audits)
      create_table :expense_audits do |t|
        t.references :expense, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.string :action, null: false
        t.jsonb :changeset, null: false, default: -> { "'{}'::jsonb" }
        t.timestamps
      end
      add_index :expense_audits, [:expense_id, :created_at]
    end

    unless table_exists?(:approval_steps)
      create_table :approval_steps do |t|
        t.references :expense, null: false, foreign_key: true
        t.integer :stage, null: false
        t.integer :decision, null: false, default: 0
        t.references :decided_by, foreign_key: { to_table: :users }
        t.datetime :decided_at
        t.text :rejection_reason
        t.timestamps
      end
      add_index :approval_steps, [:expense_id, :stage], unique: true
      add_check_constraint :approval_steps, "stage IN (0, 1)", name: "approval_steps_stage_valid"
      add_check_constraint :approval_steps, "decision IN (0, 1, 2)", name: "approval_steps_decision_valid"
    end

    unless table_exists?(:reimbursements)
      create_table :reimbursements do |t|
        t.references :expense, null: false, foreign_key: true, index: { unique: true }
        t.integer :status, null: false, default: 0
        t.datetime :paid_at
        t.timestamps
      end
      add_check_constraint :reimbursements, "status IN (0, 1, 2, 3)", name: "reimbursements_status_valid"
    end

    unless table_exists?(:external_transactions)
      create_table :external_transactions do |t|
        t.references :team, null: false, foreign_key: true
        t.references :expense, foreign_key: true
        t.string :external_id, null: false
        t.integer :amount_cents, null: false
        t.string :description, null: false
        t.date :transacted_on, null: false
        t.integer :status, null: false, default: 0
        t.text :review_reason
        t.timestamps
      end
      add_index :external_transactions, [:team_id, :external_id], unique: true
      add_index :external_transactions, [:team_id, :status]
      add_check_constraint :external_transactions, "amount_cents > 0", name: "external_transactions_amount_positive"
      add_check_constraint :external_transactions, "status IN (0, 1, 2)", name: "external_transactions_status_valid"
    end
  end
end
