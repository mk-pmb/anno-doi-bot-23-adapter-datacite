// -*- coding: utf-8, tab-width: 2 -*-

import isStr from 'is-string';
import mustBe from 'typechecks-pmb/must-be.js';
import mustLookupPropInDict from 'must-lookup-prop-in-dict-pmb';
import objPop from 'objpop';

import kisi from './kisi.mjs';


const EX = function transformAuthor(annoAuthor) {
  mustBe('obj', annoAuthor);
  // email homepage iana:alternate id name type
  const popAut = objPop(annoAuthor, { mustBe }).mustBe;
  popAut('nonEmpty str | undef', 'email');
  const dataCiteCreator = {
    name: popAut.nest('name'),
    nameType: EX.translateNameType(popAut.nest),
    affiliation: [],
    nameIdentifiers: [],
  };

  kisi.popMapList(popAut, 'homepage', function each(orig) {
    EX.parseWebsite(orig, dataCiteCreator);
  });
  kisi.popMapList(popAut, 'iana:alternate', function each(orig) {
    EX.parseWebsite(orig, dataCiteCreator);
  });

  return dataCiteCreator;
};


Object.assign(EX, {

  nameTypesDict: {
    // Anno Model Agent type -> DataCite nameType
    Person: 'Personal',
  },

  translateNameType(popNest) {
    return mustLookupPropInDict('nameType', popNest, EX.nameTypesDict, 'type');
  },


  parseWebsite(orig, dataCiteCreator) {
    const ws = EX.parseWebsiteFundamentals(orig);
    if (!ws) { return; }

    const rorId = kisi.cutStrPrefix(ws.url, 'https://ror.org/');
    if (rorId) {
      dataCiteCreator.affiliation.push({
        affiliationIdentifierScheme: 'ROR',
        schemeUri: 'https://ror.org/',
        affiliationIdentifier: ws.url,
        name: ws.name,
      });
      return;
    }

    const orcId = kisi.cutStrPrefix(ws.url, 'https://orcid.org/');
    if (orcId && /^(?:\d{4}-){3}/.test(orcId)) {
      dataCiteCreator.nameIdentifiers.push({
        nameIdentifierScheme: 'ORCID',
        schemeUri: 'https://orcid.org/',
        nameIdentifier: ws.url,
      });
      return;
    }

    console.warn('W: Discarding uncategorized author website URL: ' + ws.url);
  },


  parseWebsiteFundamentals(orig) {
    if (isStr(orig)) { return { url: orig }; }
    mustBe.obj('website record', orig);
    const popWs = objPop(orig, { mustBe }).mustBe;
    const atCtx = popWs.nest('@context');
    const ctxWeb = kisi.httpOrHttpsUrlWithoutProtocol(atCtx);
    const atType = popWs.nest('@type');
    if (ctxWeb === 'schema.org/') {
      if (atType === 'Webpage') {
        const url = popWs.nest('url');
        const name = popWs('nonEmpty str | undef', 'name');
        return { url, name };
      }
    }
    return false;
  },


});






export default EX;
