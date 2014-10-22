class CreateBattingStats < ActiveRecord::Migration
  def change
    create_table :batting_stats do |t|
      t.string 	    :player_ref_id, null: false, index: true
      t.string		  :year, index: true
      t.string      :team_id, index: true
      t.string      :league, index: true
      t.integer     :games, default: 0
      t.integer     :at_bats, default: 0, index: true
      t.integer     :runs, default: 0
      t.integer     :hits, default: 0
      t.integer     :doubles, default: 0
      t.integer     :triples, default: 0
      t.integer     :hr, default: 0, index: true
      t.integer     :rbi, default: 0, index: true
      t.integer     :sb, default: 0
      t.integer     :cs, default: 0
      t.float       :batting_avg, default: 0.0, index: true
      t.float       :slug, default: 0.0
      t.timestamps
    end
  end
end
