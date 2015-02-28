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
arrayRemove = require("array-remove")
schedule = require("node-schedule")

voteOpeningCron = new schedule.RecurrenceRule()
voteOpeningCron.hour = 17
voteOpeningCron.minute = 0

voteClosingCron = new schedule.RecurrenceRule()
voteClosingCron.hour = 7
voteClosingCron.minute = 0

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

    return "Choose your favourites links of the day: \n#{text}"


  getEmptyVoteErrorMessage = ->
    return "No links have been shared today.\nCome on! share something! :pray:"


  # Returns the links list stored in redis.
  getLinks = ->
    return robot.brain.get("daily-links")


  # Override the links list.
  setLinks = (links) ->
    robot.brain.set("daily-links", links)


  # from "1, 2, 3" to [0, 1, 2]
  extractVoteIndex = (voteMessage) ->
    return voteMessage
      .replace(/,\s?/g, " ").split(" ")
      # Only keep integers, ignore the rest.
      .filter (value) ->
        return value.length > 0 and !isNaN(value)
      # Transform it to match the `links` index
      .map (value) ->
        return parseInt(value, 10) - 1


  # Votes are closed between 7am to 5pm.
  canUserVote = ->
    date = new Date()
    h = date.getHours()
    return h < 7 and h >= 17


  # Executed every day at 17.00.
  # It displays a message in the general channel
  schedule.scheduleJob voteOpeningCron, ->
    return if getLinks().length == 0
    robot.messageRoom "general", "It's time to vote! :hammer:\n#{getLinksToChooseMessage()}"


  # Executed every day at 7.00
  # I sends the vote data to the server.
  schedule.scheduleJob voteClosingCron, ->
    return if getLinks().length == 0
    # TODO send the data to the server


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
    unless canUserVote()
      msg.send "Be patient my friend. You can't vote before 17.00."
      return

    user = msg.message.user.name
    links = getLinks()

    if links.length == 0
      msg.send getEmptyVoteErrorMessage()
      return

    vote = extractVoteIndex(msg.match[1])

    # Upvote
    vote.forEach (linkIndex) ->
      links[linkIndex].vote = []
      linkVote = links[linkIndex].vote
      if linkVote.indexOf(user) == -1
        linkVote.push(user)

    # Build the list for the end message.
    voteMessage = vote.map (linkIndex) -> "- #{links[linkIndex].url}"

    msg.send """
      You have voted for:
      #{voteMessage.join("\n")}
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
      .map (link, index) ->
        return "- #{index + 1}: #{link.url}"

    if userVotes.length == 0
      msg.send "You haven't voted today."
    else
      msg.send "You have voted for:\n#{userVotes.join("\n")}"


  # If the user wants to unvote a vote he did.
  # Example:
  # @bernarbot unvote all
  # @bernarbot unvote 1, 2
  robot.respond /unvote (.*)/i, (msg) ->
    vote = msg.match[1]
    user = msg.message.user
    links = getLinks()

    if vote == "all"
      links.forEach (link) -> arrayRemove(link.vote, user.name)
      msg.send "All your votes have been removed. Vote again!"
      return

    voteIndex = extractVoteIndex(msg.match[1])
    # Remove the vote from the links data.
    voteIndex.forEach (index) -> arrayRemove(links[index].vote, user.name)
    # Build the list for the end message.
    voteMessage = voteIndex.map (index) -> "- #{links[index].url}"

    msg.send "Your votes have been removed:\n#{voteMessage.join("\n")}"


  if !getLinks() then setLinks([])
