require 'erubis'
require 'hashie'
require 'imdb'
require 'plex-ruby'
require 'tvdb_party'
require 'pry'
require 'dotenv'
Dotenv.load

template = File.read("email.html.erb")
template = Erubis::Eruby.new(template)

tvdb = TvdbParty::Search.new(ENV['TVDB_KEY'])

Plex.configure do |config|
  config.auth_token = ENV['PLEX_TOKEN']
end
server = Plex::Server.new(ENV['PLEX_IP'], 32400)
newest_movies = server.library.section(1).recently_added[0..3] # only take the most recent
newest_shows = server.library.section(2).recently_added[0..3] # only take the most recent

# get info and urls for movies
movies = []
newest_movies.each do |m|
  m.attribute_hash["guid"].match /imdb:\/\/tt(.*)\?lang/i
  imdb_id = $1
  movies << Imdb::Movie.new(imdb_id) unless imdb_id.nil?
end

shows = []
newest_shows.each do |tv|
  tv.attribute_hash["guid"].match /tvdb:\/\/(.*)\?lang/i
  ids = $1.split('/')
  shows << tvdb.get_series_by_id(ids[0]) unless ids.nil?
end

#binding.pry

File.write('./rendered.html', template.result(plex_movies: newest_movies, movies: movies, plex_shows: newest_shows, tvdb: shows) )
