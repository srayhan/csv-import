# spec/models/player_spec.rb 
require 'rails_helper'

RSpec.describe Player, :type => :model do

	describe "with stats" do

		before :all do 
			@player1 = FactoryGirl.create(:player, player_ref_id: "player1") 
			@player2 = FactoryGirl.create(:player, player_ref_id: "player2") 
			FactoryGirl.create(:player, player_ref_id: "player3") 

			FactoryGirl.create(:batting_stat, player_ref_id: "player1", games: 142, at_bats: 502, runs: 121, hits: 171, doubles: 40,  triples: 5, hr: 16, rbi: 78) 
			FactoryGirl.create(:batting_stat, player_ref_id: "player1", year: '2010', games: 154, at_bats: 550, runs: 88, hits: 203, doubles: 41,  triples: 1, hr: 20, rbi: 78) 
			FactoryGirl.create(:batting_stat, player_ref_id: "player2", games: 154, at_bats: 550, runs: 88, hits: 203, doubles: 41,  triples: 1, hr: 20, rbi: 101) 
			FactoryGirl.create(:batting_stat, player_ref_id: "player3", games: 92, at_bats: 195, runs: 28, hits: 48, doubles: 8,  triples: 1, hr: 3, rbi: 19) 
		end

		after(:all) do
	  		Player.destroy_all
	  		BattingStat.destroy_all
		end

		it 'finds triple crown winner given a league and year with a default minimum at_bats of 400' do
			expect(Player.triple_crown_winner('AL', 2009)).to eq(@player2)
		end

		it 'finds improved batter given two years with a default minimum at_bats of 400' do
			expect(Player.most_improved_batter('2009', '2010')['player']).to eq(@player1)
		end
	end

end