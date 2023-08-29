// -*- coding: utf-8, tab-width: 2 -*-

const EX = Object.assign([

  { rights: 'Creative Commons Zero v1.0 Universal',
    rightsUri: 'https://creativecommons.org/publicdomain/zero/1.0/',
    rightsIdentifierScheme: 'SPDX',
    schemeUri: 'https://spdx.org/licenses/',
    rightsIdentifier: 'cc0-1.0',
  },


], {

  byUrl(url) { return EX.find(e => (e.rightsUri === url)) || false; },

});


export default EX;
