// -*- coding: utf-8, tab-width: 2 -*-

import getown from 'getown';
import isStr from 'is-string';
import mustBe from 'typechecks-pmb/must-be.js';
import mustLookupPropInDict from 'must-lookup-prop-in-dict-pmb';
import objPop from 'objpop';

import classifyingSchemas from './classifyingSchemas.mjs';
import kisi from './kisi.mjs';

function fail(why, ass) { throw Object.assign(new Error(why), ass); }

const ignoreValues = Boolean; // cheap built-in no-op


const EX = function parseAllBodies(popAnno) {
  const state = {
    report: {
      gndSubjects: [],
      relationLinks: [],
      textBodyLanguages: [],
    },
  };
  kisi.popMapList(popAnno, 'body', EX.parseOneBody.bind(null, state));
  const r = state.report;
  r.firstTextBodyLanguage = r.textBodyLanguages[0] || '';
  return r;
};


Object.assign(EX, {

  nameTypesDict: {
    // Anno Model Agent type -> DataCite nameType
    Person: 'Personal',
  },

  translateNameType(popNest) {
    return mustLookupPropInDict('nameType', popNest, EX.nameTypesDict, 'type');
  },


  parseOneBody(state, origBody, bodyIdx) {
    if (isStr(origBody)) { fail("String body isn't currently supported."); }
    mustBe.obj('body', origBody);
    const bType = ('t' + (origBody.type || '')
      + '_p' + (origBody.purpose || '')
    );
    const specializedParser = getown(EX.bodyParsersByType, bType);
    const bTrace = ('Body #' + (bodyIdx + 1)
      + ' (' + (bType || 'untyped') + ')');
    if (!specializedParser) {
      console.error(bTrace + ':', origBody);
      fail('Unsupported body type: ' + bType);
    }
    const popBody = objPop(origBody,
      { mustBe, mustBeDescrPrefix: bTrace + ' field ' }).mustBe;
    return specializedParser(state, popBody);
  },


  bodyParsersByType: {

    tTextualBody_p(state, popBody) {
      EX.checkTextBodyLanguage(state, popBody);
    },

    tSpecificResource_pclassifying(state, popBody) {
      const title = popBody.nest('dc:title');
      const source = popBody.nest('source');
      const { prefix, parse } = classifyingSchemas.byUrlPrefix(source);
      if (!parse) { fail('No body parser for classifying source ' + source); }
      const ctx = {
        source,
        prefix,
        subUrl: source.slice(prefix.length),
        title,
        state,
        popBody,
      };
      parse(ctx);
    },

    tSpecificResource_plinking(state, popBody) {
      const predicate = popBody.nest('rdf:predicate');
      const title = popBody.nest('dc:title');
      const rela = {
        resourceTypeGeneral: 'Text',
        relationType: 'References',
        relatedIdentifierType: 'URL',
        relatedIdentifier: popBody.nest('source'),
      };
      state.report.relationLinks.push(rela);
      ignoreValues(predicate, title);
    },

  },


  checkTextBodyLanguage(state, popBody) {
    const bl = popBody('str | undef', 'language');
    if (!bl) { return; }
    const had = state.report.textBodyLanguages;
    if (had.includes(bl)) { return; }
    had.push(bl);
  },


});






export default EX;
