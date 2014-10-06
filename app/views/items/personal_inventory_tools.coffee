module.exports = class PersonalInventoryTools extends Backbone.Marionette.ItemView
  template: require 'views/items/templates/personal_inventory_tools'
  events:
    'click #addItem': -> app.execute 'show:entity:search'
    'keyup #itemsTextFilterField': 'executeTextFilter'
    'change select#listingPicker': 'updateListingFilter'

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
    app.execute 'textFilter', Items.personal.filtered, $('#itemsTextFilterField').val()

  updateListingFilter: (e)->
    selected = e.currentTarget.value
    switch selected
      when 'none' then app.execute 'filter:visibility:reset'
      else app.execute 'filter:visibility', selected