require 'open-uri'
require 'nokogiri'

class Game
  attr_accessor :name, 
    :id, 
    :minplayers, 
    :maxplayers, 
    :recommended, 
    :best, 
    :avgweight,
    :playingtime

  def initialize(name, id, info)
    @name = name
    @id = id
    @minplayers = info['minplayers']
    @maxplayers = info['maxplayers']
    @avgweight = info['avgweight']
    @playingtime = info['playingtime']
    @recommended = info['suggested']['recommended']
    @best = info['suggested']['best']
  end
end

def numeric_only?(str)
  !str.match("[^0-9]")
end

def suggested_count(poll_result, keyword)
  counts = []
  for result in poll_result
    count = result.attr("numplayers")
    if numeric_only?(count)
      recommended = result.xpath("result[@value='#{keyword}']").attr('numvotes').value
      if recommended.to_i > 0
        counts << count
      end
    end
  end
  return counts.join(",")
end

def suggested_players(item)
  suggested_players = item.xpath("poll[@name='suggested_numplayers']/results")
  recommended = suggested_count(suggested_players, "Recommended")
  best = suggested_count(suggested_players, "Best")
  return {"recommended" => recommended, "best" => best}
end

def get_game(id)
  xml = Nokogiri::XML(open("http://www.boardgamegeek.com/xmlapi2/thing?id=#{id}&type=boardgame&stats=1"))
  item = xml.xpath("//item")[0]
  {
    'minplayers' => item.xpath("minplayers").attr("value").value,
    'maxplayers' => item.xpath("maxplayers").attr("value").value,
    'playingtime' => item.xpath("playingtime").attr("value").value,
    'avgweight' => item.xpath("statistics/ratings/averageweight").attr('value').value,
    'suggested' => suggested_players(item)
  }
end

def get_ranked_games(page)
  # doc = Nokogiri::HTML(open("http://boardgamegeek.com/search/boardgame/page/#{page}?sort=rank&advsearch=1"))
  doc = Nokogiri::HTML(File.open('page1.html'))
  links = doc.css('td.collection_objectname a')
  games = []
  for link in links
    name = link.content
    id = link['href'].match('/boardgame/([0-9]+)/')[1]
    info = get_game(id)
    game = Game.new(name, id, info)
    puts "#{game.name}: #{game.id}, #{game.playingtime} min, #{game.minplayers}-#{game.maxplayers} players, rec w #{game.recommended}, best w #{game.best}, #{game.avgweight} weight"
    games << game
  end
  return games
end

games = []
games = get_ranked_games(1)
# for x in 1..5
#   games << get_ranked_games(x)
#   games.flatten!
# end

# for game in games
#   puts "#{game.name}: #{game.id}, #{game.minplayers}-#{game.maxplayers}, #{game.recommend} #{game.best} #{game.avgweight}"
# end
