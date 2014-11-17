module.exports = class PersonalInventoryTools extends Backbone.Marionette.ItemView
  tagName: 'div'
  className: 'row toolsWrapper'
  template: require './templates/personal_inventory_tools'
  events:
    'click #addItem': -> app.execute 'show:entity:search'
    'keyup #itemsTextFilterField': 'executeTextFilter'
    'change select#listingPicker': 'updateListingFilter'
    'click a.lines': 'dispositionLines'
    'click a.boxes': 'dispositionBoxes'

  serializeData: ->
    listings = _.toArray(app.user.listings)
    none =
      selected: true
      icon: 'circle-o'
      id: 'none'
      label: _.i18n 'All'
      unicodeIcon: '&#xf10c'
    listings.unshift(none)

    attrs =
      listings: listings
      isFirefox: _.isFirefox()
    return attrs

  executeTextFilter: ->
    text = $('#itemsTextFilterField').val()
    Items.personal.filtered.filterByText text, false

  updateListingFilter: (e)->
    selected = e.currentTarget.value
    switch selected
      when 'none' then app.execute 'filter:visibility:reset'
      else app.execute 'filter:visibility', selected

  onShow: -> app.inventory.showMenuBar()
  onDestroy: -> app.inventory.hideMenuBar()

  dispositionBoxes: -> @toggleActiveButton()
  dispositionLines: -> @toggleActiveButton()

  toggleActiveButton: -> $('.disposition > a').toggleClass('active')