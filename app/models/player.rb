require 'csv'

class Player < ActiveRecord::Base

   has_many :batting_stats, foreign_key: :player_ref_id, primary_key: :player_ref_id, inverse_of: :player, dependent: :destroy

   validates :player_ref_id, uniqueness: true

   def self.import(file_with_path, batch_size=100)
     CSV::HeaderConverters[:rename_headers] = lambda do |field|
      case field
      when 'playerID'
         'player_ref_id'
      when 'birthYear'
         'birth_year'
      when 'nameFirst'
         'first_name'
      when 'nameLast'
         'last_name'
      else
         raise Error, "unknow column name- #{name}"
      end
     end
     players = []
     players_missing_ids = []
     results = []
     CSV.foreach(file_with_path, {headers: true, header_converters: :rename_headers, converters: :all, skip_blanks: true}) do |player|
       logger.debug("adding user- #{player.inspect}")
       if player['player_ref_id'].present?
         players << player.to_hash
       else
         players_missing_ids << player.to_hash
       end
       #let's batch them up 
       if players.count == batch_size
         ActiveRecord::Base.transaction do
            results << Player.create(players)
            players = []
         end
       end
     end
     #create the last batch
     if players.present?
      ActiveRecord::Base.transaction do
         results << Player.create(players)
      end
     end
     logger.info("#{results.flatten.count} players added.")
     logger.error("could not process #{players_missing_ids.count} records for missing player id.")
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
