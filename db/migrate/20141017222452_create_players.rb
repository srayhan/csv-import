class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string  :player_ref_id, null: false, unique: true, index: true
      t.string  :first_name
      t.string  :last_name
      t.string    :birth_year
      t.timestamps
    end
  end
end
