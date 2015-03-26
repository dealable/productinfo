tableScraper
============
scrape table data using CSS selectors
- scrapes any url
- get header using cheerio.js
- get data using jquery/jsdom
- get both data using lapwinglabs/x-ray
- currently outputs in text. need to structure and JSON the data

uses:
- meteor
- cheerio.js
- jquery/jsdom
- lapwinglabs/x-ray
- jade
- coffeescript

Demo is available here:
http://tablescraper.meteor.com

todo:
- parse x-ray data text to tableObject then find a JS version of console.table
- add link to twitter feed