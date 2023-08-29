// -*- coding: utf-8, tab-width: 2 -*-

import arrayOfTruths from 'array-of-truths';


const EX = {

  popMapList(mustPop, key, convert) {
    let list = arrayOfTruths(mustPop('ary | obj | str | undef | nul', key));
    if (convert) { list = list.map(convert).filter(Boolean); }
    return list;
  },


  httpOrHttpsUrlWithoutProtocol(url) {
    if (!url) { return ''; }
    if (!url.startsWith) { return ''; }
    const m = /^https?:\/{2}/.exec(url);
    if (!m) { return ''; }
    return url.slice(m[0].length);
  },


  cutStrPrefix(s, p) { return (s.startsWith(p) ? s.slice(p.length) : ''); },


};


export default EX;
