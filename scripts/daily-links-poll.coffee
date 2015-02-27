# Description
#   Todo
#
# Dependencies:
#   hubot-redis-brain
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Author:
#   Antoine Lehurt

urlNorm = require("url-norm")

module.exports = (robot) ->

  # Returns the text containing the links list.
  getLinksToChooseMessage = ->
    links = getLinks()

    if !links or links.length == 0
      return getEmptyVoteErrorMessage()

    if links.length == 1
      return "Just one link today:\n- 1: #{links[0].url}"

    # In the first iteration, `previous` is the first index and `current` the second.
    text = links.reduce (previous, current, index) ->
      if typeof previous is "object"
        previous = "- #{index}: #{previous.url}"
      return "#{previous}\n- #{index + 1}: #{current.url}"

    return "Choose your favourites links of the day: \n#{text} \n DM me `vote 1 2 3`"


  getEmptyVoteErrorMessage = ->
    return "No links have been shared today.\nCome on! share something! :pray:"


  # Returns the links list stored in redis.
  getLinks = ->
    return robot.brain.get("daily-links")


  # Override the links list.
  setLinks = (links) ->
    robot.brain.set("daily-links", links)


  if !getLinks() then setLinks([])
  # If an user share a link, we saved it.
  robot.hear /(\w+)\:\/\/([^\/\:]*)(\:\d+)?(\/?.*)/i, (msg) ->
    links = getLinks()
    user = msg.message.user
    url = urlNorm(msg.match[0])

    urlExists = links.some (data) -> data.url == url
    return if urlExists

    links.push
      user: user
      url: url
      vote: []
      channel: msg.message.room

    setLinks(links)


  # If an user ask for the list (via mention or direct message).
  # The bot display the list of links if there is something to show.
  # Example: @bernarbot list
  robot.respond /list/i, (msg) ->
    msg.send getLinksToChooseMessage()


  # Vote for a link (via mention or direct message).
  # Example: @bernarbot vote 1, 2, 3
  robot.respond /vote (.*)/i, (msg) ->
    # date = new Date()
    # if date.getHours() < 17
    #   msg.send "Be patient my friend. You can't vote before 17.00."
    #   return

    user = msg.message.user.name
    links = getLinks()

    if links.length == 0
      msg.send getEmptyVoteErrorMessage()
      return

    vote = msg.match[1]
      .replace(/,\s?/g, ' ').split(' ')
      # Only keep integers, ignore the rest.
      .filter (value) ->
        return value.length > 0 and !isNaN(value)
      # Transform it to match the `links` index
      .map (value) ->
        return parseInt(value, 10) - 1

    # Upvote
    vote.forEach (linkIndex) ->
      links[linkIndex].vote = []
      linkVote = links[linkIndex].vote
      if linkVote.indexOf(user) == -1
        linkVote.push(user)

    voteMessage = vote.map (linkIndex) ->
      return "- #{links[linkIndex].url}"

    msg.send """
      You have voted for:
      #{voteMessage.join('\n')}
      Good job :+1:

      (If you change you mind you can unvote: `unvote all` or `unvote 1, 2`).
    """


  robot.respond /vote$/i, (msg) ->
    msg.send "You can vote like this: `vote 1, 2, 3`"


  # Displays the list of links the user has voted for
  robot.respond /my\s*vote/i, (msg) ->
    user = msg.message.user
    links = getLinks()

    if links.length == 0
      msg.send "You haven't voted today because no links have been shared."
      return

    userVotes = links
      .filter (link) ->
        return link.vote.indexOf(user.name) > -1
      .map (link) ->
        return "- #{link.url}"

    if userVotes.length == 0
      msg.send "You haven't voted today."
    else
      msg.send "You have voted for:\n#{userVotes.join('\n')}"



