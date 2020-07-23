Ext.define('Gw.override.Editor', {
  override: 'Ext.Editor',
  completeOnEnter: false, // Do not dismiss editor or lose focus on ENTER key

  _unboxCellValue:function (value) {
    var item = gw.GridUtil.getFirstInputInTemplateCell(value);
    if (item) {
      value = item['value']
    }

    if (value) {
      // unbox composite value
      if (value.value !== undefined) {
        return value.value; // use editValue if any
      } else if (value.text !== undefined) {
        return value.text;
      }
    }
    return value
  },

  initComponent: function () {

    /** Do not complete edit yet, if we need to confirm the value change */
    this.on('beforecomplete', function (editor, value, startValue) {

      var field = editor.field;
      if (field.skipConfirm) {
        return; // it has been confirmed already
      }

      // show confirmation dialog, if value has changed:
      if (field.confirm && value !== startValue) {
        gw.app.confirm('', field.confirm, function (btn) {
          if (btn == 'yes' || btn == 'ok') { // confirmed

            field.skipConfirm = true; // do not confirm again for this change
            editor.completeEdit();
            field.fireEvent('blurchange', field, value, startValue);
            delete field.skipConfirm;

          } else { // cancelled:
            editor.cancelEdit();
          }
        });

        return false;
      }
    });

    //
    // When click to edit a bounded dropdown cell, open menu
    // When tab to edit a text cell, select all text.
    //
    this.on('startedit', function (ed) {
      // @SenchaUpgrade what's the best way to distinguish "clicking" vs "tabbing" into a cell editor?
      if (Ext.EventObject.type == 'click') { // click to edit

        if (ed.field instanceof gw.ext.SimpleCombo) {
          ed.field.on('focus', function () { // wait till the field gets focus
            ed.field.selectText();
            ed.field.onTriggerClick();
          }, null, {single: true})
        }

      } else if (Ext.EventObject.type == 'blur') { // tab to edit

        if (ed.field instanceof Ext.form.field.Text) {
          ed.field.on('focus', function () { // wait till the field gets focus
            ed.field.selectText();
          }, null, {single: true});
        }
      }
    });

    this.callParent(arguments);
  },

  /**
   * Replaces the base implementations so that it doesn't cancelEdit and clear the field
   * if the inputMask validation fails (PLWEB-4287).
   */
  completeEdit : function(remainVisible) {
    var me = this,
        field = me.field,
        value;

    if (!me.editing) {
      return;
    }

    // Assert combo values first
    if (field.assertValue) {
      field.assertValue();
    }

    value = me.getValue();

    if (String(value) === String(me.startValue) && me.ignoreNoChange) {
      me.hideEdit(remainVisible);
      return;
    }

    if (me.fireEvent('beforecomplete', me, value, me.startValue) !== false) {
      // Grab the value again, may have changed in beforecomplete
      value = me.getValue();
      if (me.updateEl && me.boundEl) {
        me.boundEl.update(value);
      }
      me.hideEdit(remainVisible);
      me.fireEvent('complete', me, value, me.startValue);
    }
  },

  /**
   * Extends base implementation to remember editor on the field
   */
  onRender: function () {
    this.callParent(arguments);
    this.field.editor = this;
  },

  /**
   * Overrides super to only edit the "text" part of a composite field
   */
  startEdit: function (el, value) {
    // Do not start extjs editor for radiogroup, radiogroups use custom rendering
    var type = this.field.xtype,
        unboxedValue = this._unboxCellValue(value);

    if (!gw.GridUtil.hasEditor(type)) {
      return false;
    }

    // TODO: Refactor: Card 372: Edit value should be a uniform value.
    this.callOverridden([el, unboxedValue]);
    // extra checking to un-register the tooltip if the field is invalid so the error message doesn't overlap with tooltip.
    // Event fired was suspended during cell start edit so validitychange event didn't get fired.
    if (this.field.tooltip) {
      if (this.field.isValid()) {
        this.field.setTooltip(this.field.tooltip, /*initial*/true);
      } else {
        this.field.clearTip();
      }
    }

    //PLWEB-3140: The default startEdit calls setValue() on the field with the cell's
    //value, but if the field is a datefield and the value does not parse, this
    //does not work. If the RawValue is not set, but there is a previous value,
    //set it directly
    if(type === "datefield" && unboxedValue && !this.field.getRawValue()) {
      this.field.setRawValue(unboxedValue);
    }
  },

  /**
   * Overrides original to returns raw value which is always a string.
   * To preserve the date format after editing (TODO: any better way?).
   */
  getValue: function () {
    return gw.ext.Util.getFieldValue(this.field);
  },

  // TODO: Refactor: HACK!!  This is to temporarily work around radiogroup inconsistency,
  // in IE, blur is triggered, in FF, blur is not triggered.
  // We may replace radiogroup composite field, so for now, will live with this
  // workaround.
  onBlur: function () {
    if (this.field.xtype == 'radiogroup') {
      gw.Debug.log('Ignoring onBlur for radiogroups' + this.field.eventParam);

    } else {
      this.callOverridden(arguments);
    }
  },

  // Need to do this otherwise we get an error in IE when the panel is destroyed.
  // Error is in insertAfter:  'parentNode is null or not an object'
  beforeDestroy: function () {

    //@SenchaUpgrade
    // TODO: assigning items to null might prevent their proper destroy() process.
    // Revisit this "IE bug" and see if there's a better solution.
    // by Sencha, April 9 2013
    if (this.field.items) {
      this.field.items = null;
    }

    this.callOverridden(arguments);
  }
});
