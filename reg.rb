require 'discordrb'
require 'uri'
require 'yaml'

token = YAML.load_file('token.yml')

bot = Discordrb::Bot.new token: token

starboard = bot.channel(799_340_653_280_362_567)

names = YAML.load_file('names.yml')

File.new('starred.yml', 'w') unless File.exist?('starred.yml')
starred = YAML.load_file('starred.yml', fallback: [])

star = '⭐'

bot.reaction_add do |event|
  begin
    next if event.emoji.name != star

    next if event.channel.nsfw

    next if event.message.reactions.find { |reaction| reaction.name == star }.count < 2

    next if starred.include?(event.message.id)

    starred.push(event.message.id)
    File.open('starred.yml', 'w') { |file| file.write(starred.to_yaml) }

    link = "https://discord.com/channels/#{event.server.id}/#{event.channel.id}/#{event.message.id}"

    starboard.send_embed do |embed|
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: "#{names.fetch(event.message.author.id,
                             event.message.author.name)} posted in ##{event.channel.name}", icon_url: event.message.user.avatar_url
      )

      if event.message.attachments.count.positive?
        embed.image = Discordrb::Webhooks::EmbedImage.new(url: event.message.attachments[0].url)
      end

      if event.message.content =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
        embed.image = Discordrb::Webhooks::EmbedImage.new(url: event.message.content)
      else
        embed.description = "#{event.message}\n"
      end

      embed.description = embed.description + "[Link](#{link})"

      embed.colour = event.message.user.color
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: event.message.timestamp.ctime)
    end
  rescue StandardError => e
    File.open('log', 'w') { |file| file.puts(e.message, "\n", e.backtrace.inspect) }
  end
end

bot.message do |event|
  next if event.user.bot_account

  next unless event.message == 'reg, status'

  event.respond("Everything's fine.")
end

bot.run
