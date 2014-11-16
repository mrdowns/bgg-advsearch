require File.dirname(__FILE__) + '/../bgg.rb'

describe BGG::AdvancedSearch do
  it "should ping bgg" do
    adv_search = BGG::AdvancedSearch.new
    expect(true).to eq(false)
  end
end
