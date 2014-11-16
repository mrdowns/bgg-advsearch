require 'open-uri'
require 'nokogiri'
require 'uri'
require 'CSV'

module BGG
	class AdvancedSearch
		def initialize(options = {})
  		@options = {
  			:sort => 'rank',
  			:advsearch => '1',
  			}.merge(options)
		end

		def page(num = 1)
			games = request_adv_search(num)
			puts games
		end

		private

		def request_adv_search(page)
			endpoint = 'http://boardgamegeek.com/search/boardgame'
			query = URI.encode_www_form(@options)

			doc = Nokogiri::HTML(open("#{endpoint}/page/#{page}?#{query}"))
			links = doc.css('td.collection_objectname a')
			links.collect { |link| {"id" => extract_id(link['href'], "name" => link.content)} }
		end

		def extract_id(href)
			href.match('/boardgame/([0-9+)/')[1]
		end
	end

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
end