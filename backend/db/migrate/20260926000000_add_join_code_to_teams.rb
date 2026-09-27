class AddJoinCodeToTeams < ActiveRecord::Migration[7.1]
  def up
    add_column :teams, :join_code, :string
    execute <<~SQL.squish
      UPDATE teams
      SET join_code = substring(md5(random()::text || clock_timestamp()::text || id::text), 1, 24)
    SQL
    change_column_null :teams, :join_code, false
    add_index :teams, :join_code, unique: true
  end

  def down
    remove_column :teams, :join_code
  end
end
