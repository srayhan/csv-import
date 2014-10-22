# spec/models/batting_stat_spec.rb 
require 'rails_helper'

RSpec.describe BattingStat, :type => :model do

	before :all do 
		FactoryGirl.create(:player, player_ref_id: "player1") 
		FactoryGirl.create(:player, player_ref_id: "player2") 
		FactoryGirl.create(:player, player_ref_id: "player3") 

		FactoryGirl.create(:batting_stat, player_ref_id: "player1", games: 142, at_bats: 502, runs: 121, hits: 171, doubles: 40,  triples: 5, hr: 16, rbi: 101) 
		FactoryGirl.create(:batting_stat, player_ref_id: "player1", year: '2010', games: 154, at_bats: 550, runs: 88, hits: 203, doubles: 41,  triples: 1, hr: 20, rbi: 78) 
		FactoryGirl.create(:batting_stat, player_ref_id: "player2", games: 154, at_bats: 573, runs: 88, hits: 146, doubles: 41,  triples: 1, hr: 20, rbi: 78) 
		FactoryGirl.create(:batting_stat, player_ref_id: "player3", games: 92, at_bats: 195, runs: 28, hits: 48, doubles: 8,  triples: 1, hr: 3, rbi: 19) 
	end

	after(:all) do
  		Player.destroy_all
  		BattingStat.destroy_all
	end

	context "when data for team, league, and year is available" do

		it 'calculates maximum batting average for a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_batting_average('AL', '2009').round(2)).to be(0.34)
		end

		it 'calculates maximum home runs or a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_home_runs('AL', '2009')).to be(20)
	    end

		it 'calculates maximum rbi for a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_rbi('AL', '2009')).to be(101) #none wins the crown
	    end

		it 'finds triple crown winning stat for a given league and year with a default minimum at_bats of 400' do
			expect(BattingStat.triple_crown_winning_stat('AL', '2009').length).to be(0)
	    end

	    it 'returns batting stats for a given team_id and year' do
			expect(BattingStat.stats('OAK', '2009').length).to be(3)
	    end

		it 'calculates yoy change batting average for a given two years with a default minimum at_bats of 200' do
			expect(BattingStat.yoy_batting_avg_change('2009', '2010')['player1']['yoy_change'].to_f.round(2)).to be(0.03)
	    end
	end

	context "when data for team, league, or year is missing" do

		it 'returns nil maximum batting average for a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_batting_average('NL', '2009')).to be(nil)
		end

		it 'returns nil maximum home runs or a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_home_runs('AL', '2011')).to be(nil)
	    end

		it 'returns nil maximum rbi for a given league and year with a default minimum at_bats of 200' do
			expect(BattingStat.max_rbi('NL', '2009')).to be(nil) 
	    end

	    it 'returns empty batting stats for a given team_id and year' do
			expect(BattingStat.stats('OAQ', '2009').length).to be(0)
	    end

	end
end