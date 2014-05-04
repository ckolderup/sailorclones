require 'rubygems'
require 'twitter'
require 'andand'
require 'optparse'
require 'obscenity'

SEARCH_QUERY="I'm afraid of "

Obscenity.configure do |config|
    config.blacklist = './blacklist.yml'
    config.replacement = :garbled
end

def has_blacklisted(text)
    terms = ["http", "heights", "David Bowie", 
             "everything", "losing you", "the dark"]
    !!text.match(Regexp.union(*terms))
end

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-t", "--tweet", "Tweet instead of printing") do |t|
        options[:tweet] = true
    end
end.parse!


client = Twitter::REST::Client.new do |config|
    config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
    config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
end

# list generated with:
# `http "api.wordnik.com/v4/words.json/search/.%2Aor" limit=='2000' allowRegex=='true' api_key==$WORDNIK_KEY | jq -c '.searchResults[] | .word '`


red_sky = nil
while red_sky.nil? do
    sailor = File.readlines('./ors.txt').sample.chomp
    red_sky = client.search("\"#{SEARCH_QUERY}\"", result_type: "recent").
        collect.take(500).flat_map { |tweet|
            tweet.text.match(/#{SEARCH_QUERY}([a-zA-Z0-9 &\-']+)/i).andand.captures.andand.first
        }.reject {|text|
            text.nil? ||
            text.length < 5 ||
            text.split(' ').size > 5 ||
            Obscenity.profane?(text) ||
            has_blacklisted(text)
        }.sample.strip
end

output = "#{red_sky} at morning, #{sailor}s take warning. #{red_sky} at night, #{sailor}s' delight"

if options[:tweet] then
    client.update output
else
    puts output
end
