Ext.define('gw.override.form.field.Time', {
    override: 'Ext.form.field.Time',

    // PLWEB-6214: check the submit value first to prevent formatting javascript error. If it's not valid, still
    // send back the value to let server side handle the validation.
    // @SenchaUpgrade override private method.
    getSubmitValue: function () {
        var me = this;
        if (!me.isValid()) {
            return me.getValue() || me.getRawValue();
        }
        return me.callParent(arguments);
    }
});