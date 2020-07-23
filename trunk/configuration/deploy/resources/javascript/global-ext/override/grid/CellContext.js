Ext.define('Gw.override.grid.CellContext', {
  override: 'Ext.grid.CellContext',

  // @SenchaUpgrade - override the private method so setPosition by index number
  // would skip the hidden columns.

  setColumn: function(col) {
    var me = this,
      mgr = me.view.ownerCt.getColumnManager();

    if (col !== undefined) {
      if (typeof col === 'number') {
        // start the override - skip hidden columns
        var columns = mgr.getColumns(),
            len = columns.length, actualIndex, visibleIndex = 0;
        for (actualIndex = 0; actualIndex < len; actualIndex++) {
          if (!mgr.getHeaderAtIndex(actualIndex).hidden) {
            if (visibleIndex == col) {
              break;
            }
            visibleIndex++;
          }
        }
        me.column = actualIndex;
        me.columnHeader = mgr.getHeaderAtIndex(actualIndex);
        // end of the override
      } else if (col.isHeader) {
        me.columnHeader = col;
        me.column = mgr.getHeaderIndex(col);
      }
    }
  }
});