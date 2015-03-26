Router.configure
  layoutTemplate: 'ApplicationLayout'
  yieldRegions:
    navbar: to: 'top'
#    urlside: to: 'aside'
#    urlbottom: to: 'footer'

Router.route '/',
  (-> @render()),
  name: 'tweets'

Router.route 'git'
Router.route 'vid'

Router.route '/post/:_id', ->
  @layout 'ApplicationLayout'

Router.route '/items', ->
  @render 'Items'

Router.route '/items/:_id', ->
  item = Items.findOne(_id: @params._id)
  @render 'ShowItem',
    data: item


Router.route '/files/:filename', (->
  @response.end 'hi from the server\n'
),
  where: 'server'

Router.route('/restful',
  where: 'server'
).get(->
  @response.end 'get request\n'
).post ->
  @response.end 'post request\n'
