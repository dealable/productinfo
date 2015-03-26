tweetUrl = "https://twitter.com/naval/status/456255410136027136"
tweetFormat = "#stream-items-id > li:nth-child(n) > div > div > p"
hockeyUrl = "http://www.hockey-reference.com/players/s/shacked01.html"
hockeyFormat = "#stats_basic_nhl > thead > tr:nth-child(2)"

if Meteor.isClient
  Template.tweets.events
    "click #bt_header": (event) ->
      Meteor.call "chScrape"
        , tb_url.value
        , tb_header.value
        , (error, result) ->
          console.log "click ", result
          Session.set "header", result
      false

    "click #bt_data": (event) ->
      Meteor.call "jqScrape"
        , tb_url.value
        , tb_data.value
        , (error, result) ->
          console.log "click ", result
          Session.set "data", result
      false

    "click #bt_table": (event) ->
      Meteor.call "xrayScrape"
        , tb_url.value
        , tb_table_root.value
        , tb_table_header.value
        , tb_table_data.value
        , (error, result) ->
          console.log "click ", result
          Session.set "table", result
      false
      
  Template.navbar.helpers
    arr3: -> [1..3]
  Template.tweets.helpers
    scrapedHeaderCount: -> (Session.get "header").length
    scrapedHeader:      -> (Session.get "header").join(" ")
    scrapedDataCount:   -> (Session.get "data").length
    scrapedData:        -> (Session.get "data").join(" ")
    scrapedTalbeCount:   -> (Session.get "table").length
    scrapedTable:        -> (Session.get "table").join(" ")

if Meteor.isServer
  Meteor.startup ->
    Meteor.call "chScrape"
      , hockeyUrl
      , hockeyFormat
      , (error, result) ->

  Meteor.methods
    ###  scrape using cheerio.js ###
    chScrape: (url, format) -> 
      html = Meteor.http.get url

      $ = Meteor.npmRequire("cheerio").load html.content
      chResults = $(format).map (i, elem) ->
          elemtext = $(elem).text().replace(/(\r\n|\n|\r)/g,"")
          console.log "chResults: ", elemtext
          elemtext
        .get()
      chResults
  
    ###  scrape using jsdom/jquery ###
    jqScrape: (url,format) ->
      html = Meteor.http.get url
      
      # http://stackoverflow.com/questions/21358015/error-jquery-requires-a-window-with-a-document
      jq = Meteor.npmRequire("jquery")(Meteor.npmRequire("jsdom").jsdom().parentWindow)
      jqDoc = jq html.content

      # http://stackoverflow.com/questions/23866237/jquery-cheerio-going-over-an-array-of-elements
      jqResults = jqDoc.find(format).map (i, elem) ->
          elemtext = jq(elem).text().replace(/(\r\n|\n|\r)/g,"")
          console.log "jqResults: ", elemtext
          elemtext
        .get()
      jqResults
      
    ###  scrape using x-ray.js ###
    xrayScrape: (url, root, header, data) -> 
#      check coffeescript self-initiating functions
      future = new (Npm.require 'fibers/future')()
      xray url
        .select([{
          $root: [root],
          headers: [header]
          data: [data]
          }])
        .run (err,rowarr)->
          rowtextarr = for row in rowarr
            rowtext = ([row.headers..., row.data...]).join(" ") 
            console.log "xrayResults", rowtext
            rowtext
          future.return rowtextarr
      xrayResults = do future.wait
      xrayResults
    #    .write(process.stdout)