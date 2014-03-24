
Inventory = require 'inventory'
InventoryWindow = require 'inventory-window'
InventoryDialog = (require 'voxel-inventory-dialog').InventoryDialog
ItemPile = require 'itempile'

module.exports = (game, opts) -> new CreativeInventoryPlugin(game, opts)

class CreativeInventoryPlugin extends InventoryDialog
  constructor: (@game, opts) ->
    @registry = game.plugins.get('voxel-registry') ? throw new Error('voxel-creative-inventory requires voxel-registry')

    div = document.createElement 'div'

    @thisInventory = new Inventory(10, 3) # TODO: multi-paged inventory
    @thisIW = new InventoryWindow {inventory:@thisInventory, registry:@registry}

    @buttons = document.createElement 'div'
    div.appendChild @buttons
    div.appendChild @thisIW.createContainer()

    super game, upper: [div]

  enable: () ->
  disable: () ->

  open: () ->
    categories = @scanCategories()
    @addButtons categories
    @populateCategory categories, @activeCategory

    super open

  addButtons: (categories) ->
    @buttons.removeChild @buttons.firstChild while @buttons.firstChild

    # sort categories, items and blocks always first
    categoryNames = Object.keys(categories)
    categoryNames.sort (a, b) ->
      a = '0items' if a == 'items'
      a = '1blocks' if a == 'blocks'
      b = '0items' if b == 'items'
      b = '1blocks' if b == 'blocks'

      if a < b
        -1
      else if a > b
        1
      else
        0

    # TODO: real tabs?
    categoryNames.forEach (category) =>
      button = document.createElement 'button'
      button.textContent = category # TODO: category icons
      button.addEventListener 'click', () =>
        # rescan and populate
        @populateCategory @scanCategories(), category

      @buttons.appendChild button

  # Scan all items/blocks and return object with categories to item names
  # Note: items/blocks can be registered at any time! Recall for latest data.
  scanCategories: () ->
    categories = {}

    # TODO: add a proper API in voxel-registry to get all items and blocks
    for name, props of @registry.itemProps
      category = props.creativeTab ? 'items'

      categories[category] ?= []
      categories[category].push name

    for props, blockIndex in @registry.blockProps
      continue if blockIndex == 0 # skip air

      name = @registry.getBlockName blockIndex
      category = props.creativeTab ? 'blocks'

      categories[category] ?= []
      categories[category].push name

    # TODO: maybe leave unsorted, so items from the same plugin are grouped together?
    # or perhaps better yet, somehow track the plugin that registered each item?
    for category, items of categories
      items.sort()

    console.log categories
    return categories

  populateCategory: (categories, category) ->
    category ?= 'items'
    @activeCategory = category

    @thisInventory.clear()

    items = categories[category] ? []

    for name, i in items
      @thisInventory.set i, new ItemPile(name, Infinity)
