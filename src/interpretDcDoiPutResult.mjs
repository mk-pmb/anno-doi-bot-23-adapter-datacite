// -*- coding: utf-8, tab-width: 2 -*-

import 'exit-code';
import 'p-fatal';
import 'usnam-pmb';

import getOwn from 'getown';
import mustBe from 'typechecks-pmb/must-be.js';
import objPop from 'objpop';

import readOneStdinRecord from './readOneStdinRecord.mjs';

function cerr(...args) { console.error('-ERR', ...args); }
function orf(x) { return x || false; }
function strOrNone(x) { return String(x || '<?none?>'); }

function topKeysList(x) { return Object.keys(orf(x)).sort(); }
function topKeysComma(x) { return strOrNone(topKeysList(x).join(', ')); }

function oneLineJson(x) {
  return JSON.stringify(x, null, 1).replace(/\n\s*/g, ' ');
}


const EX = {

  async nodemjsCliMain() {
    const apiReply = await readOneStdinRecord();
    const topKeys = topKeysComma(apiReply);
    if (topKeys === 'errors') { return EX.gotErrorsReply(apiReply.errors); }
    if (topKeys === 'data') { return EX.gotDataReply(apiReply.data); }
    throw new Error('Unexpected top-level keys in API reply: ' + topKeys);
  },


  visibilityStates: {
    draft: 'draft',
    findable: 'public',
    registered: 'hidden',
  },


  gotErrorsReply(origErrReply) {
    process.exitCode = 4;
    if (!origErrReply) { return cerr('reported an error without any reason.'); }
    const errList = [].concat(origErrReply);
    const nErrs = errList.length;
    if (nErrs === 1) { return cerr('API error:', EX.fmtApiErr(errList[0])); }
    const multi = 'Multiple API errors';
    console.error('E: %s (n=%s):', multi, nErrs);
    errList.forEach(e => console.error('  •', EX.fmtApiErr(e)));
    cerr(multi);
  },


  fmtApiErr(origErr) {
    const { status, ...details } = origErr;
    let det = oneLineJson(details);
    det = (det === '{}' ? '' : ' ' + det);
    return ((status || '<?no status?>') + det);
  },


  gotDataReply(apiData) {
    const replyType = strOrNone(apiData.type);
    if (replyType === 'dois') { return EX.gotDoisReply(apiData); }
    console.debug('API reply:', apiData);
    throw new Error('Unexpected "type" API reply data: ' + replyType);
  },


  gotDoisReply(apiData) {
    const popData = objPop(apiData, { mustBe }).mustBe;
    popData('eeq:"dois"', 'type');
    popData('obj', 'relationships');
    const topId = popData('nonEmpty str', 'id');
    const attr = popData('obj', 'attributes');
    if (attr.doi !== topId) {
      const msg = ('Oddity in API reply data: DOIs do not match:'
        + ' Top-level "id" field = ' + JSON.stringify(topId)
        + ' vs. "attributes.id" field = ' + JSON.stringify(attr.id));
      throw new Error(msg);
    }
    popData.expectEmpty('Unexpected leftover keys in API reply data');
    const visibility = (getOwn(EX.visibilityStates, attr.state) || 'unknown');
    console.info('<urn:doi:%s> %s', topId, visibility);
  },


};


export default EX;
