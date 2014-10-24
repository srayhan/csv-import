

class Player < ActiveRecord::Base
   include CsvImportable

   has_many :batting_stats, foreign_key: :player_ref_id, primary_key: :player_ref_id, inverse_of: :player, dependent: :destroy

   validates :player_ref_id, uniqueness: true

   def self.valid_record?(player)
      player['player_ref_id'].present?
   end

   def self.record_new?(player)
      !Player.where("player_ref_id = ?", player['player_ref_id']).first.present?
   end

   def self.headers_map
      {
         'playerID' => 'player_ref_id',
         'birthYear' => 'birth_year',
         'nameFirst' => 'first_name',
         'nameLast' => 'last_name'
      }
   end

   # Triple crown winner – The player that had the highest batting average AND the most home runs AND the most RBI in their league.
   # A minimum of 400 at-bats is used to determine those eligible for the league batting title.
   def self.triple_crown_winner(league, year, minimum_at_bats = 400)
     winning_stat = BattingStat.triple_crown_winning_stat(league, year, minimum_at_bats)
     winning_stat.present? ? winning_stat.first.player : nil
   end

   def self.most_improved_batter(year1, year2, minimum_at_bats = 200)
     batting_avg_change_stats = BattingStat.yoy_batting_avg_change(year1, year2, minimum_at_bats)
     logger.debug("#{batting_avg_change_stats.map{|k, v| v["yoy_change"]}}")
     most_improved_stat = batting_avg_change_stats.first
     most_improved_stat.present? ? {"player" => Player.where("player_ref_id = ?", most_improved_stat[0]).first,
                                     "yoy_change" => most_improved_stat[1]["yoy_change"]} : {}
   end
end
