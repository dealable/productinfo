amzn =
  url: "http://www.amazon.com/Apple-iPhone-Gold-16-GB/dp/B00NQGP3SO/ref=sr_1_1?s=wireless&ie=UTF8&qid=1427391459&sr=1-1&keywords=iphone+6"
  root: "#a-page"
  title: "#productTitle"
  img: "#landingImage"
  dataroot: "#productDetailsTable .content ul"
  header: "li b"
  data: "li"

tweetUrl = "https://twitter.com/naval/status/456255410136027136"
tweetFormat = "#stream-items-id > li:nth-child(n) > div > div > p"
hockeyUrl = "http://www.hockey-reference.com/players/s/shacked01.html"
hockeyFormat = "#stats_basic_nhl > thead > tr:nth-child(2)"

if Meteor.isClient
  Template.tweets.events
    "click #bt_amzn": (event) ->
      templ =
        url: tb_amzn.value
        root: tb_amzn_root.value
        title: tb_amzn_title.value
        img: tb_amzn_img.value
        dataroot: tb_amzn_dataroot.value
        header: tb_amzn_header.value
        data: tb_amzn_data.value
        
      Meteor.call "xrayScrape"
        , templ
#        , tb_amzn.value
#        , tb_amzn_root.value
#        , tb_amzn_header.value
#        , tb_amzn_data.value
#        , tb_amzn_title.value
#        , tb_amzn_img.value
        , (error, result) ->
          console.log "click ", result
          Session.set "table", result
      false

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
      Meteor.call "xrayScrapeText"
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
    amznUrl: -> amzn.url
    amznRoot: -> amzn.root
    amznTitle: -> amzn.title
    amznImg: -> amzn.img
    amznDataroot: -> amzn.dataroot
    amznHeader: -> amzn.header
    amznData: -> amzn.data
    scrapedHeaderCount: -> (Session.get "header").length
    scrapedHeader:      -> (Session.get "header").join(" ")
    scrapedDataCount:   -> (Session.get "data").length
    scrapedData:        -> (Session.get "data").join(" ")
    scrapedTalbeCount:   -> (Session.get "table").length
    scrapedTable:        -> (Session.get "table").join(" ")

if Meteor.isServer
  Meteor.startup ->
    Meteor.call "chScrape"
      , amzn.url
      , amzn.root + amzn.header
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
          elemtext = jq(elem).val().replace(/(\r\n|\n|\r)/g,"")
          console.log "jqResults: ", elemtext
          elemtext
        .get()
      jqResults
      
    ###  scrape using x-ray.js ###
    xrayScrapeText: (url, root, header, data) -> 
#      check coffeescript self-initiating functions
      future = new (Npm.require 'fibers/future')()
      xray url
        .select([{
          $root: [root],
          headers: [header]
          data: [data]
#          headers: [header]
#          data: [data]
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
    
    
    xrayScrape: (templ) -> 
      console.log "start", templ
#      check coffeescript self-initiating functions
      future = new (Npm.require 'fibers/future')()
      rmNewLines = (str) -> str.replace(/(\r\n|\n|\r)/g,"").trim()
      xray templ.url
        # prepare can only (str->str) but do as much as possible
        .prepare('rmNewLines', rmNewLines)
        .select({
          name: templ.name,
          img: templ.img,
          info: {
            $root: templ.dataroot,
            details: [{
              field: templ.header + " | rmNewLines" # | rmColon | rmNewLines",
              data: templ.data + " | rmNewLines" # | rmHeaderName"  # + " | " +  rmHeaderName  + " | " + rmJS  
            }]
          }})
        .run (err,product)->
          for detail in product.info.details
            header = detail.field
            if header in ["Amazon Best Sellers Rank:", "Average Customer Review:"]
              detail.data = ""
            else
              detail.data = detail.data.replace(header,"").trim()
            detail
          future.return product
#        .write(process.stdout)
      xrayResults = do future.wait
      console.log "xrayResults",  (JSON.stringify xrayResults) #.replace(/\n/g, "\\n") lost newline formating
      xrayResults