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
