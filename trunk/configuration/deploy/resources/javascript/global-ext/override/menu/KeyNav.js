Ext.define('Gw.override.menu.KeyNav', {
    override: 'Ext.menu.KeyNav',

    //modify escape key listener, so it will fire event
    escape: function (e) {
        var menu = this.menu;
        menu.deactivateActiveItem(true);

        Ext.menu.Manager.hideAll();
        this.menu.fireEvent('escape', this);
    },

    //Fix Menu hiding for Multi column menus
    left: function (e) {
        var menu = this.menu,
            fi = menu.focusedItem;

        if (fi && this.isWhitelisted(fi)) {
            return true;
        }

        if (menu.multiColumnMenu ) {

            //if we are in menu #0 -> hide

            if(menu.columnPosition === 0){
                if (menu.parentMenu) {
                    menu.deactivateActiveItem(true);
                    menu.up().hide();
                    menu.parentMenu.focus();
                }
            }else{
                //else, move focus to menu on the left
                var leftMenu = menu.up().down('menu[columnPosition='+ (menu.columnPosition - 1) +']');
                if(leftMenu){
                    menu.deactivateActiveItem(true);
                    this.focusFirstItem(leftMenu);
                }
            }
        } else {
            if (menu.parentMenu) {
                menu.hide();
                menu.parentMenu.focus();
            }
        }
    },

    right: function(e) {
        var menu = this.menu,
            fi = menu.focusedItem,
            ai = menu.activeItem,
            parent = menu.up(),
            subMenu = ai ? ai.menu : null;

        //check for an item on the right
        if (parent && !subMenu) {
            var rightMenu = menu.up().down('menu[columnPosition='+ (menu.columnPosition + 1) +']');
            if(rightMenu){
                menu.deactivateActiveItem(true);
                this.focusFirstItem(rightMenu);
                return true;
            }
        }

        if (fi && this.isWhitelisted(fi)) {
            return true;
        }

        if (subMenu) {
            ai.expandMenu(0);
            subMenu.setActiveItem(subMenu.child(':focusable'));
        }
    },

    focusFirstItem: function(menu){
        var items = menu.items,
            len = items.length,
            i,
            item;

        for(i = 0; i < len ; i++){
            item = items.getAt(i);
            if (menu.canActivateItem(item)) {
                menu.setActiveItem(item);
                break;
            }
        }
    },

    //Override changes the way how first item is selected. It checks for the first available one whreas original just tries to focus the first
    down: function(e) {
        var me = this,
            fi = me.menu.focusedItem,
            multiColumnMenu = me.menu.down('menu[multiColumnMenu=true]');

        if (fi && e.getKey() == Ext.EventObject.DOWN && me.isWhitelisted(fi)) {
            return true;
        }

        if(!fi && multiColumnMenu){
            me.focusFirstItem(multiColumnMenu);
        }else{
            me.focusNextItem(1);
        }
    },

    //Prevent from going up in multi column menu if nothing has been focused
    up: function(e) {
        var me = this,
            fi = me.menu.focusedItem,
            multiColumnMenu = me.menu.down('menu[multiColumnMenu=true]');

        if (fi && e.getKey() == Ext.EventObject.UP && me.isWhitelisted(fi)) {
            return true;
        }

        if(!fi && multiColumnMenu){
            return true;
        }else{
            me.focusNextItem(-1);
        }
    }
});
