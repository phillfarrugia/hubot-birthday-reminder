# Description:
#   Track birthdays for users
#
# Dependencies:
#   "node-schedule": "^0.2.9"
#   "moment": "^2.10.6"
#
# Commands:
#   set birthday @username dd/mm/ - Set a date of birth for a user
#   hubot list birthdays - List all set date of births
#
# Notes:
#   Birthday greeting messages based on Steffen Opel's
#   https://github.com/github/hubot-scripts/blob/master/src/scripts/birthday.coffee
#
# Author:
#   Phill Farrugia <me@phillfarrugia.com>

schedule = require('node-schedule')
moment = require('moment')

module.exports = (robot) ->

  regex = /^(set birthday) (?:@?([\w .\-]+)\?*) ((0?[1-9]|[12][0-9]|3[01])\/(0?[1-9]|1[0-2]))\b/i

  # runs a cron job every day at 9:30 am
  dailyBirthdayCheck = schedule.scheduleJob '0 30 09 * * 0-7', ->
    console.log "checking today's birthdays..."
    birthdayUsers = findUsersBornOnDate(moment(), robot.brain.data.users)

    if birthdayUsers.length is 1
      # send message for one users birthday
      msg = "<!channel> Today is <@#{birthdayUsers[0].name}>'s birthday!"
      msg += "\n#{quote()}"
      robot.messageRoom "#general", msg
    else if birthdayUsers.length > 1
      # send message for multiple users birthdays
      msg = "<!channel> Today is "
      for user, idx in birthdayUsers
        msg += "<@#{user.name}>'s#{if idx != (birthdayUsers.length - 1) then " and " else ""}"
      msg += " birthday!"
      msg += "\n#{quote()}"
      robot.messageRoom "#general", msg

  robot.hear regex, (msg) ->
    name = msg.match[2]
    date = msg.match[3]
    
    users = robot.brain.usersForFuzzyName(name)
    if users.length is 1
      user = users[0]
      user.date_of_birth = date
      msg.send "#{name} is now born on #{user.date_of_birth}"
    else if users.length > 1
      msg.send getAmbiguousUserText users
    else
      msg.send "#{name}? Never heard of 'em"

  robot.respond /list birthdays/i, (msg) ->
    users = robot.brain.data.users
    if users.length is 0
      msg.send "I don't know anyone's birthday"
    else
      message = ""
      for k of (users or {})
        user = users[k]
        if isValidBirthdate user.date_of_birth
          message += "#{user.name} was born on #{user.date_of_birth}\n"
      msg.send message

  getAmbiguousUserText = (users) ->
    "Be more specific, I know #{users.length} people named like that: #{(user.name for user in users).join(", ")}"

  # returns `array` of users born on a given date
  findUsersBornOnDate = (date, users) ->
    matches = []
    for k of (users or {})
      user = users[k]
      if isValidBirthdate user.date_of_birth
        if equalDates date, moment(user.date_of_birth, "DD/MM")
          matches.push user
    return matches

  # returns `true` is date string is a valid date
  isValidBirthdate = (date) ->
    if date
      if date.length > 0
        if moment(date, "DD/MM").isValid
          return true
    return false

  # returns `true` if two dates have the same month and day of month
  equalDates = (dayA, dayB) ->
    return (dayA.month() is dayB.month()) && (dayA.date() is dayB.date())

  quotes = [
      "Hoping that your day will be as special as you are.",
      "Count your life by smiles, not tears. Count your age by friends, not years.",
      "May the years continue to be good to you. Happy Birthday!",
      "You're not getting older, you're getting better.",
      "May this year bring with it all the success and fulfillment your heart desires.",
      "Wishing you all the great things in life, hope this day will bring you an extra share of all that makes you happiest.",
      "Happy Birthday, and may all the wishes and dreams you dream today turn to reality.",
      "May this day bring to you all things that make you smile. Happy Birthday!",
      "Your best years are still ahead of you.",
      "Birthdays are filled with yesterday's memories, today's joys, and tomorrow's dreams.",
      "Hoping that your day will be as special as you are.",
      "You'll always be forever young.",
      "Happy Birthday, you're not getting older, you're just a little closer to death.",
      "Birthdays are good for you. Statistics show that people who have the most live the longest!",
      "I'm so glad you were born, because you brighten my life and fill it with joy.",
      "Always remember: growing old is mandatory, growing up is optional.",
      "Better to be over the hill than burried under it.",
      "You always have such fun birthdays, you should have one every year.",
      "Happy birthday to you, a person who is smart, good looking, and funny and reminds me a lot of myself.",
      "We know we're getting old when the only thing we want for our birthday is not to be reminded of it.",
      "Happy Birthday on your very special day, I hope that you don't die before you eat your cake."
  ]

  quote = (name) ->
    quotes[(Math.random() * quotes.length) >> 0]
