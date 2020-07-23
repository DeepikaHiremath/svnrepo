Ext.define('Gw.override.form.field.Display', {
  override: 'Ext.form.field.Display',

  /**
   * Flatten out the provided array into a joined array.
   * This is mainly for multi-select in read only mode but might be used for other things
   */
  setValue : function (value){
    var me = this;
    // This is mainly for multi-select in read only mode but might be used for other things
    //PLWEB-6169 / PLWEB-6190
    if (Ext.isArray(value)){
      var newValue = [];
      for (var i = 0; i < value.length; i++) {
        var arrayValue = value[i];
        if (arrayValue.preHtml) {
          newValue.push(arrayValue.preHtml);
        }
        if (arrayValue.value) {
          newValue.push(arrayValue.value);
        }
        if (arrayValue.postHtml) {
          newValue.push(arrayValue.postHtml);
        }
      }
      value = newValue.join('<br>');
    }
    return me.callParent(arguments);
  }
});
