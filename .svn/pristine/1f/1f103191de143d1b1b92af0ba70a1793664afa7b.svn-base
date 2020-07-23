/**
 * Extends auto-complete with ENTER key behavior
 */
Ext.define('gw.ext.QuickJump', {
  extend: 'gw.ext.AutoComplete',
  alias: 'widget.quickjump',
  shortcut: '/',
  typeAhead: true,
  typeAheadDelay: 10,
  queryDelay: 10,
  queryCaching : false,


  listConfig: {
    tpl: '<tpl for="."><div class="x-boundlist-item">{listText:decodeMetaTags}</div></tpl>'
  },

  initComponent: function () {
    this.emptyText = gw.app.localize('Web.QuickJump') + ' (Alt+/)';
    this.callParent(arguments);
    /**
     * call server when the ENTER key is pressed
     */
    this.on('specialkey', function (field, e) {
      if (e.getKey() == e.ENTER) {
        // select the highlighted item first if there is any
        if (this.listKeyNav) {
          this.listKeyNav.selectHighlighted(e);
        }
        // post to server
        gw.app.handleAction(e, field.getEl().dom,
          {postCallback: function () {
            field.clearValue()
          }, postCallbackScope: field})
      }
    });
   /**
    * PLWEB-5029 Quick Jump list behavior is not always consistent
    *
    * QuickJump changes depending on the page context and the quick-jump widget is rarely destroyed so always force a
    * remoteQuery
    */
    this.queryMode = "remote";
  },

  updateEmptyText: function () {
    this.emptyText = gw.app.localize('Web.QuickJump') + ' (Alt+/)';
    this.applyEmptyText();
  }
});
