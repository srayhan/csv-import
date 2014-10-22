namespace :baseball do
	
	desc "This task prints out answers to 3 qusestions in the exercise!"
	task :stats => :environment do
		puts "Q.1> Who has the most improved batting average( hits / at-bats) from 2009 to 2010? (Only include players with at least 200 at-bats)"

		player_with_stat = Player.most_improved_batter(2009, 2010)
		puts " Answer> #{player_with_stat["player"].first_name} #{player_with_stat["player"].last_name} is the most improved batter from 2009 to 2010 with an year over year improvement #{player_with_stat["yoy_change"].round(2) *100}%"

		puts "Q.2> Slugging percentage for all players on the Oakland A's (teamID = OAK) in 2007."

		stats = BattingStat.stats("OAK", 2007)

		puts "Answer> Player ID     Slugging Percentage"

		stats.each_with_index do |stat, index|
		 	puts "#{index}        #{stat.player_ref_id}     #{stat.slug.present? ? stat.slug.round(2) : 0}   "
		 end

		 puts "Q.3> Who was the AL and NL triple crown winner for 2011 and 2012. If no one won the crown, output (No winner)"

		 puts " League    Year    Winner"

		 player = Player.triple_crown_winner("AL", 2011)
		 player.present? ? puts("   AL     2011     #{player.first_name} #{player.last_name}") : puts("   AL     2011     No winner")

		 player = Player.triple_crown_winner("AL", 2012)
		 player.present? ? puts("   AL     2012     #{player.first_name} #{player.last_name}") : puts("   AL     2012     No winner")

		 player = Player.triple_crown_winner("NL", 2011)
		 player.present? ? puts("   NL     2011     #{player.first_name} #{player.last_name}") : puts("   NL     2011     No winner")

		 player = Player.triple_crown_winner("NL", 2012)
		 player.present? ? puts("   NL     2012     #{player.first_name} #{player.last_name}") : puts("   NL     2012     No winner")
	end

	desc "This task loads data to database: usage rake baseball:load[<file_name_with_path>,<model name>]"
	task :load, [:file_with_path, :model] => :environment do |task, args|
		raise "missing parameters. USAGE: rake baseball:load[<file_with_path>,<model name>]" unless args[:file_with_path] && args[:model]
		#raise "model #{args[:model]} not found" unless Object.const_defined?(args[:model].to_s)
		clazz = args[:model].constantize
		raise "data load is not supported yet for model #{args[:model]}" unless clazz and clazz.respond_to?(:import)
		clazz.import(args[:file_with_path])
	end

end