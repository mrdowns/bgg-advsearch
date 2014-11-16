require 'open-uri'
require 'nokogiri'
require 'CSV'

class Game
  attr_accessor :name, 
    :id, 
    :minplayers, 
    :maxplayers, 
    :recommended, 
    :avgweight,
    :playingtime

  def initialize(name, id, info)
    @name = name
    @id = id
    @minplayers = info['minplayers']
    @maxplayers = info['maxplayers']
    @avgweight = info['avgweight']
    @playingtime = info['playingtime']
    @recommended = info['recommended']
  end
end

def numeric_only?(str)
  !str.match("[^0-9]")
end

def suggested_players(item)
  poll_results = item.xpath("poll[@name='suggested_numplayers']/results")
  recommended_counts = []
  for result in poll_results
    count = result.attr("numplayers")
    if numeric_only?(count)
      recommended = result.xpath("result[@value='Recommended']").attr('numvotes').value
      not_recommended = result.xpath("result[@value='Not Recommended']").attr('numvotes').value
      if recommended.to_i > 0 && recommended.to_i > not_recommended.to_i
        recommended_counts << count
      end
    end
  end
  return recommended_counts.join(",")
end

def get_game(id)
  xml = Nokogiri::XML(open("http://www.boardgamegeek.com/xmlapi2/thing?id=#{id}&type=boardgame&stats=1"))
  item = xml.xpath("//item")[0]
  {
    'minplayers' => item.xpath("minplayers").attr("value").value,
    'maxplayers' => item.xpath("maxplayers").attr("value").value,
    'playingtime' => item.xpath("playingtime").attr("value").value,
    'avgweight' => item.xpath("statistics/ratings/averageweight").attr('value').value,
    'recommended' => suggested_players(item)
  }
end

def get_ranked_games(page)
  doc = Nokogiri::HTML(open("http://boardgamegeek.com/search/boardgame/page/#{page}?sort=rank&advsearch=1"))
  # doc = Nokogiri::HTML(File.open('page1.html'))
  links = doc.css('td.collection_objectname a')
  games = []
  for link in links
    name = link.content
    id = link['href'].match('/boardgame/([0-9]+)/')[1]
    info = get_game(id)
    game = Game.new(name, id, info)
    puts "#{game.name}: #{game.id}, #{game.playingtime}m, #{game.minplayers}-#{game.maxplayers}, r #{game.recommended}, #{game.avgweight} w"
    games << game
  end
  return games
end

games = []
# games = get_ranked_games(1)

for x in 1..5
  games << get_ranked_games(x)
  games.flatten!
end

def get_weight(num)
  if num < 2
    return "light"
  elsif num < 3
    return "medium"
  else
    return "heavy"
  end
end

CSV.open('output.csv', 'wb') do |csv|
  csv << ["name","weight","minplayers","maxplayers","playingtime","recplayers"]
  for game in games
    weight = get_weight(game.avgweight.to_f)
    csv << [game.name, weight, game.minplayers, game.maxplayers, game.playingtime, game.recommended]
  end
end

# for x in 1..5
#   games << get_ranked_games(x)
#   games.flatten!
# end

# for game in games
#   puts "#{game.name}: #{game.id}, #{game.minplayers}-#{game.maxplayers}, #{game.recommend} #{game.best} #{game.avgweight}"
# end
