#!/usr/bin/env rake
require 'dotenv'
require 'erubis'
require 'imdb'
require 'plex-ruby'
require 'pony'
require 'pry'
require 'tvdb_party'

Dotenv.load

Plex.configure do |config|
  config.auth_token = ENV['PLEX_TOKEN']
end

server = Plex::Server.new(ENV['PLEX_IP'], ENV['PLEX_PORT'] || 32400)

class PosterFetcher
  def self.poster_for(plex_video)
    if plex_video.guid.match /imdb:\/\/tt(.*)\?lang/i
      imdb_id = $1
      Imdb::Movie.new(imdb_id).poster
    elsif plex_video.guid.match /tvdb:\/\/(.*)\?lang/i
      ids = $1.split('/')
      @@tvdb ||= TvdbParty::Search.new(ENV['TVDB_KEY'])
      @@tvdb.get_series_by_id(ids[0]).posters('en').first.url
    end
  end
end

namespace :plex do
  task :sections do
    server.library.sections.each do |s|
      puts "#{s.title} - ID: #{s.key.split('/').last}"
    end
  end
end

namespace :email do
  task :generate do
    template = File.read("email.html.erb")
    template = Erubis::Eruby.new(template)

    # fetch some recently added content
    movie_section = server.library.section(ENV['PLEX_MOVIE_SECTION'])
    tv_section = server.library.section(ENV['PLEX_TV_SECTION'])
    newest_movies = movie_section.recently_added[0..3]
    newest_shows = tv_section.newest[0..3]

    potw = movie_section.all.detect { |m| m.title =~ /#{ENV['POTW']}/i }

    File.write('./rendered.html', template.result(movies: newest_movies, shows: newest_shows, potw: potw))
  end

  task :send do
    ENV['EMAILS'].split(" ").each do |address|
      puts "Sending email to #{address}..."
      Pony.mail({
         subject: "Plex Weekly",
         from: ENV['FROM_EMAIL'],
         html_body: File.read('rendered.html'),
         to: address,
         via: :smtp,
         via_options: {
           address: ENV['SMTP_ADDRESS'],
           port: ENV['SMTP_PORT'] || '587',
           user_name: ENV['SMTP_USER'],
           password: ENV['SMTP_PASS'],
           domain: ENV['SMTP_DOMAIN']
         }
      })
    end
  end
end
