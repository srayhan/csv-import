# spec/factories/players.rb 
require 'faker' 

FactoryGirl.define do 
	factory :batting_stat do |f| 
  
	  player_ref_id 'player1'

	  league 'AL'

	  team_id 'OAK'

	  year   '2009'
	end

end