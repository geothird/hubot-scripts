# Description
#   Have a question? ask and hubot will ask sagedump.com.
#   Add your own questions and answers to sagedump via hubot.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SAGEDUMP_KEY=<your user api key from sagedump.com>
#
# Commands:
#   ask: <your question here>? - Returns an answer to your question.
#   add: <your question here>? <your answer here> - Adds the q/a to sagedump.
#
# Notes:
#   A specific sagedump account can be specified via sage=[:sage_id]
#
# Author:
#   geothird

# Sagedump configuration variables
base_url = "http://sagedump.com"
api_key  = process.env.HUBOT_SAGEDUMP_KEY

search_api = "/search.json"
dumps_api  = "/dumps.json"

dont_know = [
  "Dunno.",
  "Not exactly sure.",
  "That's a really good question.",
  "Let me check on that.",
  "/me shrugs",
  "Look at the time! Gotta go!",
  "I haven't looked at that yet.",
  "IDK my BFF Jill?",
  "I think that's in my lab notebook.",
  "Huh.",
  "I don't know.",
  "You know, there are some questions that we haven't been able to answer.",
  "There are many possibilities.",
  "I don't have that information right now, maybe you should tell me.",
  "Good question. Let me get back to you on that.",
  "I've been wondering the same thing. Let's find out together.",
  "Let me double-check and then get back to you.",
  "Bleh, I know that’s an easy question! Maybe I’ll remember what it is later.",
  "I know the answer, but if I told you I would have to kill you.",
  "That is one of the great mysteries of our time.",
  "I don't think that question has been answered yet."
]

added_thanks = [
  "Got it.",
  "Umm ok.",
  "Well thats interesting.",
  "Good to know.",
  "Alright.",
  "Didn't know that.",
  "Facinating.",
  "Riveting.",
  "Amusing.",
  "Intriguing.",
  "Knowing is half the battle."
]

wtf_error = [
  "Hrmm.. not sure what happened.",
  "Reset by peer.",
  "Request was pwnt.",
  "idk wtf."
]

module.exports = (robot) ->
  # Ask the sages a question
  robot.hear /ask\: (.*)\?/i, (msg) ->
    get_answer msg, (answer) ->
      msg.send answer

  # Create a new dump from robot input
  robot.hear /add\: (.*)\? (.*)/i, (msg) ->
    add_question msg, (response) ->
      msg.send response

  # Get an answer from sagedump
  get_answer = (msg, answer_handler) ->
    goto = "#{base_url}#{search_api}?query=#{encodeURI(msg.match[1])}"
    msg.http(goto).get() (error, response, body) ->
      return answer_handler "Question reset by peer." if error
      return answer_handler "Answer reset by peer."   if response.statusCode == 404
      return answer_handler "Access denied noob."     if response.statusCode == 403
      return answer_handler "This should work.."      if response.statusCode == 401
      return answer_handler "Server got pwnt."        if response.statusCode == 500

      answers = JSON.parse(body)

      if answers && answers.length > 0
        for answer in answers
          if answer.answer
            answer_handler answer.answer
          else
            answer_handler msg.random dont_know
          break
      else
        answer_handler msg.random dont_know

  # Add a question to sage dump using api_key
  add_question = (msg, question_handler) ->
    addto = base_url + dumps_api
    pkg =
      api_key: api_key
      dump:
        question: msg.match[1]+'?'
        answer: msg.match[2]
    req = msg.http(addto)

    req.headers 'Content-Type': 'application/json'
    req.post(JSON.stringify(pkg)) (error, response, body) ->
      return question_handler "Question reset by peer." if error
      return question_handler "Question reset by beer." if response.statusCode == 404
      return question_handler "Access denied noob."     if response.statusCode == 403
      return question_handler "Server got pwnt."        if response.statusCode == 500
      return question_handler "Forgot your key?"        if response.statusCode == 401

      dump = JSON.parse(body)

      if dump
        question_handler msg.random added_thanks
      else
        question_handler msg.random wtf_error

