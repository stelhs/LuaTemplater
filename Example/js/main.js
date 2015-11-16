var blockIds = [
    {
        blockId: 'basicSettings',
        menuItemId: 'basicSettingsMenuItem'
    }, {
        blockId: 'securitySettings',
        menuItemId: 'securitySettingsMenuItem'
    }, {
        blockId: 'listOfClients',
        menuItemId: 'listOfClientsMenuItem'
    }
];

var hide = function (elementId) {
    blockIds.forEach (function (element) {
        var block = document.getElementById(element.blockId);
        var menuItem = document.getElementById(element.menuItemId);

        if (element.blockId !== elementId) {
            block.setAttribute('class', 'hidden');
            menuItem.setAttribute('class', '');
        } else {
            block.setAttribute('class', '');
            menuItem.setAttribute('class', 'active');
        }
    });
};
