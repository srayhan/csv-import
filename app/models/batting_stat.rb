require 'csv'

class BattingStat < ActiveRecord::Base
   include CsvImportable

   belongs_to :player, foreign_key: :player_ref_id, primary_key: :player_ref_id, inverse_of: :batting_stats

   before_create :set_derived_stats

   def self.valid_record?(player)
      player['player_ref_id'].present?
   end

   def self.record_new?(stat)
      !BattingStat.where("player_ref_id = ?", stat['player_ref_id']).first.present?
   end

   def self.headers_map
      {
         'playerID' => 'player_ref_id',
         'yearID'   => 'year',
         'league'   => 'league',
         'teamID'   => 'team_id',
         'G'        => 'games',
         'AB'       => 'at_bats',
         'R'        => 'runs',
         'H'        => 'hits',
         '2B'       => 'doubles',
         '3B'       => 'triples',
         'HR'       => 'hr',
         'RBI'      => 'rbi',
         'CS'       => 'cs',
         'SB'       => 'sb'
      }
   end

   def self.max_batting_average(league, year, minimum_at_bats=200)
      BattingStat.where("league = ? and year = ? and at_bats >= ?", league, year, minimum_at_bats).maximum(:batting_avg)
   end

   def self.max_home_runs(league, year, minimum_at_bats=200)
      BattingStat.where("league = ? and year = ? and at_bats >= ?", league, year, minimum_at_bats).maximum(:hr)
   end

   def self.max_rbi(league, year, minimum_at_bats=200)
      BattingStat.where("league = ? and year = ? and at_bats >= ?", league, year, minimum_at_bats).maximum(:rbi)
   end

   # Triple crown winning stat – The player that had the highest batting average AND the most home runs AND the most RBI in their league.
   # A minimum of 400 at-bats is used to determine those eligible for the league batting title.
   def self.triple_crown_winning_stat(league, year, minimum_at_bats=400)
      BattingStat.where("league = ? and year = ? and batting_avg = ? and hr = ? and rbi = ?", league, year, max_batting_average(league, year, minimum_at_bats), max_home_runs(league, year, minimum_at_bats), max_rbi(league, year, minimum_at_bats))
   end

   def self.stats(team_id, year)
      BattingStat.where("team_id = ? and year = ?", team_id, year)
   end

   # returns a hash of year over year batting average( hits / at-bats) changes. Only includes players with at least 200 at-bats.
   # format of data returned: { "<player_ref_id>" => {"yoy_change" => value, "year1" => <batting_avg>, "year2" => <batting_avg>}}
   # change_in_batting _avg = <year2 batting avg> - <year1 batting avg>  
   def self.yoy_batting_avg_change(year1, year2, minimum_at_bats=200)
      stats = BattingStat.where("(year = ? or year = ?) and at_bats >= ?", year1, year2, minimum_at_bats)
      logger.debug("#{stats.inspect}")
      yoy_batting_avg_change = stats.inject({}) do |memo, stat| 
         if memo[stat.player_ref_id].present?
            memo[stat.player_ref_id][stat.year.to_s] = stat.batting_avg
         else
            memo[stat.player_ref_id] = {stat.year.to_s => stat.batting_avg }
         end
         if memo[stat.player_ref_id][year1.to_s].present? &&  memo[stat.player_ref_id][year2.to_s].present? 
            memo[stat.player_ref_id]["yoy_change"] = memo[stat.player_ref_id][year2.to_s] - memo[stat.player_ref_id][year1.to_s]
         else
            memo[stat.player_ref_id]["yoy_change"] = 0.0
         end
         memo
      end
      #sort the stat by "yoy change" DESC
      stats = Hash[yoy_batting_avg_change.sort_by{ |k, v| v["yoy_change"]}.reverse]
      logger.debug("#{stats.map{|k, v| v["yoy_change"]}}")
      stats
    end

    private

    def set_derived_stats
      self.doubles ||= 0 
      self.triples ||= 0 
      self.hits ||= 0 
      self.hr ||= 0
      self.at_bats ||= 0
      self.batting_avg = self.hits.to_f / self.at_bats if self.at_bats > 0
      slug_total = (hits - doubles - triples) + (2 * doubles) + (3 * triples) + (4 * hr) 
      self.slug = slug_total.to_f / at_bats if at_bats > 0
   end

end
