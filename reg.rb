require 'discordrb'
require 'uri'
require 'yaml'

token = YAML.load_file('token.yml')

bot = Discordrb::Bot.new token: token

starboard = bot.channel(799_340_653_280_362_567)

names = YAML.load_file('names.yml')

star = '⭐'

bot.reaction_add do |event|
  next if event.emoji.name != star

  next if event.message.reactions.find { |reaction| reaction.name == star }.count != 1

  link = "https://discord.com/channels/#{event.server.id}/#{event.channel.id}/#{event.message.id}"

  starboard.send_embed do |embed|
    embed.title = "#{names.fetch(event.message.author.id, event.message.author.name)} posted in ##{event.channel.name}"

    if event.message.attachments.count.positive?
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: event.message.attachments[0].url)
    end

    if event.message.content =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: event.message.content)
    else
      embed.description = "#{event.message}\n"
    end

    embed.description = embed.description + "[Link](#{link})"

    embed.colour = 0xff0000
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: event.message.timestamp.ctime)
  end
end

bot.message(with_text: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.run
