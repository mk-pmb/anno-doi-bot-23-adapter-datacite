// -*- coding: utf-8, tab-width: 2 -*-

import mustBe from 'typechecks-pmb/must-be.js';
import readRelaxedJsonFromStdin from 'read-relaxed-json-from-stdin-pmb';


const EX = async function readOneStdinRecord() {
  const input = await readRelaxedJsonFromStdin();
  mustBe('pos num', 'Number of input records')(input.length);
  const first = mustBe('obj', 'Input record #1 (the annotation)')(input[0]);
  if (input.length > 1) {
    throw new Error('Unexpectad additional input records.');
  }
  return first;
};


export default EX;
