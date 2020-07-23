Ext.define('Gw.override.menu.Menu', {
  override: 'Ext.menu.Menu',

  // @SenchaUpgrade override private method to work around ExtJs bug:
  // Specifying default type for menu items on the menu is not supported
  lookupItemFromObject: function (cmp) {
    if (cmp.xtype == null && this.defaultType != null && this.defaultType != 'panel') {
      cmp.xtype = this.defaultType;
    }
    return this.callOverridden(arguments);
  },
  /**
   * Extends super to support multi-column and flattened menu:
   */
  initComponent: function () {
    var me = this,
        cols, mItem;
    var items = me.items || (Ext.isArray(me.initialConfig) ? me.initialConfig : me.initialConfig.items);
    var bMultiColumn = me.numEntriesPerColumn > 0 && items && items.length > me.numEntriesPerColumn;
    if (bMultiColumn) { // multi-column menu

      Ext.apply(me, {
        border: false,
        bodyBorder: false,
        plain: true,
        showSeparator: false
      });
      me.addCls(Ext.baseCSSPrefix + 'columnmenu');
      me.items = [];

      var column = [];
      var position = 0;
      var itemsInColumn = 0;
      for (var i = 0; i < items.length; i++) {
        if (me.flattened) {
          gw.ext.Util.appendAndFlattenMenu(items[i], column)
        } else {
          column.push(items[i])
        }

        if (items[i].xtype !== 'menuseparator') {
          itemsInColumn++;
        }
        if (itemsInColumn == me.numEntriesPerColumn) {
          me.items.push({items: column, multiColumnMenu: true, columnPosition: position++});
          column = [];
          itemsInColumn = 0;
        }
      }
      if (column.length > 0) {
        me.items.push({items: column, multiColumnMenu: true, columnPosition: position})
      }

      me.defaults = Ext.applyIf({
        floating: false,
        plain: true,
        flex: 1,
        style: {height: '100%'},
        border: false,
        bodyBorder: false,
        xtype: 'menu',
        cls: Ext.baseCSSPrefix + 'columnmenu-inner',
        defaultType: 'gmenuitem'
      }, me.defaults);

      if (Ext.isArray(me.initialConfig)) {
        me.initialConfig = undefined
      } else if (me.initialConfig) {
        me.initialConfig.items = undefined
      }
    }
    else if (me.flattened) { // flattened single-column menu
      var flattened = [];
      Ext.each(me.items, function (item) {
        gw.ext.Util.appendAndFlattenMenu(item, flattened)
      });
      delete me.items;
      me.items = flattened
    }

    me.callOverridden(arguments);

    if (bMultiColumn) {
      // force overriding the hard-coded layout of menu at the end:
      me.layout = {
        type: 'table',
        autoScroll: true,
        tableAttrs: {
          cls: Ext.baseCSSPrefix + 'columnmenu-table'
        },
        tdAttrs: {
          // AHK - 4/23/2013 - The cls here on tdAttrs appears to have no affect on the rendering.  The one
          // attached to tableAttrs, however, works
          cls: Ext.baseCSSPrefix + 'columnmenu-cell',
          style: {"vertical-align": "top"}
        }
      };

      // PLWEB-5393 There exist edge cases that highlight stays from previous hover
      // Turn-off all highlights on top level multi-column menu items
      me.on ('hide', function() {
        cols = me.items.items;  //columns
        Ext.each(cols, function (item) {
          mItem = item.items.items; //menu items in each column
          Ext.each(mItem, function (item) {
            item.el.removeCls(item.activeCls);
          });
        });
      });

    }
  }

});
