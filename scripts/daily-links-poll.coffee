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
  unless robot.brain.get("daily-links")
    robot.brain.set("daily-links", [])

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


  robot.hear /(\w+)\:\/\/([^\/\:]*)(\:\d+)?(\/?.*)/i, (msg) ->
    dailyLinks = robot.brain.get("daily-links")
    user = msg.message.user
    url = urlNorm(msg.match[0])

    urlExists = dailyLinks.some (data) -> data.url == url
    return if urlExists

    dailyLinks.push
      user: user
      url: url

    robot.brain.set("daily-links", dailyLinks)
    console.log robot.brain.get("daily-links")


  robot.respond /list/i, (msg) ->
    date = new Date()
    if date.getHours() < 17
      msg.send """
        Be patient my friend. I can't send the list before 17.00
      """
      return

    msg.send linksToChooseMessage()


  linksToChooseMessage = () ->
    links = robot.brain.get("daily-links")
    text = links.reduce (previous, current, index) ->
      if typeof previous is 'object'
        previous = "- #{index}: #{previous.url}"
      return "#{previous}\n- #{index + 1}: #{current.url}"

    return "Choose your favourites links of the day: \n#{text}"
