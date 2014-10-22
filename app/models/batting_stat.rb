require 'csv'

class BattingStat < ActiveRecord::Base

	belongs_to :player, foreign_key: :player_ref_id, primary_key: :player_ref_id, inverse_of: :batting_stats

	before_create :set_derived_stats

	def self.import(file_with_path, batch_size=1000)
	  CSV::HeaderConverters[:rename_headers] = lambda do |field|
		case field
		when 'playerID'
			'player_ref_id'
		when 'yearID'
			'year'
		when 'league'
			'league'
		when 'teamID'
			'team_id'
		when 'G'
			'games'
		when 'AB'
			'at_bats'
		when 'R'
			'runs'
		when 'H'
			'hits'
		when '2B'
			'doubles'
		when '3B'
			'triples'
		when 'HR'
			'hr'
		when 'RBI'
			'rbi'
		when 'CS'
			'cs'
		when 'SB'
			'sb'
		else
			raise "unknow column name- #{field}"
		end
	  end
	  stats = []
	  stats_missing_ids = []
	  results = []
      CSV.foreach(file_with_path, {headers: true, row_sep: :auto, header_converters: :rename_headers, converters: :all, skip_blanks: true}) do |stat|
	      logger.debug("adding a stat- #{stat.inspect}")
	      stat = stat.to_hash
	      if stat['player_ref_id'].present?
	      	# set the values to 0 if not provided to help with the calculations
	      	stat['doubles'] = 0 if stat['doubles'].nil?
	      	stat['triples'] = 0 if stat['triples'].nil?
	      	stat['hits'] = 0 if stat['hits'].nil?
	      	stat['hr']   = 0 if stat['hr'].nil?
	      	stat['at_bats'] = 0 if stat['at_bats'].nil?
	      	stats << stat
	      else
	      	stats_missing_ids << stat
	      end
	      #let's batch them up 
	      if stats.count == batch_size
	      	ActiveRecord::Base.transaction do
	      		results << BattingStat.create(stats)
	      		stats = []
	      	end
	      end
	  end
	  #create the last batch
	  if stats.present?
	  	ActiveRecord::Base.transaction do
	  		results << BattingStat
	  		.create(stats)
	  	end
	  end
	  logger.info("#{results.flatten.count} stats added.")
	  logger.error("could not process #{stats_missing_ids.count} records for missing player id.")
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
    	self.batting_avg = self.hits.to_f / self.at_bats if self.at_bats > 0
        slug_total = (hits - doubles - triples) + (2 * doubles) + (3 * triples) + (4 * hr) 
	    self.slug = slug_total.to_f / at_bats if at_bats > 0
	end

end
