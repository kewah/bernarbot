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
