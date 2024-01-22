// -*- coding: utf-8, tab-width: 2 -*-

import mustBe from 'typechecks-pmb/must-be.js';


const mustBePosInt = mustBe('pos int');

function isoOrNull(d) { return (d.getTime() ? d.toISOString() : null); }

const EX = function fmtDateAttrs(popAnno, ctx) {
  const attr = { dates: [] };
  const currentVersionCreated = new Date(popAnno.nest('created'));
  let initialVersionDate = currentVersionCreated;
  const { hasPreviousVersion } = ctx;
  if (hasPreviousVersion) {
    initialVersionDate = new Date(ctx.initialVersionDate || NaN);
    attr.updated = isoOrNull(currentVersionCreated);
  }
  attr.publicationYear = mustBePosInt('Year part of date of initial version',
    initialVersionDate.getFullYear());
  attr.created = isoOrNull(initialVersionDate);
  if (ctx.debugLevel >= 4) {
    console.warn('D: fmtDateAttrs:', {
      created: String(attr.created),
      updated: String(attr.updated),
    });
  }

  function addDate(k, v) {
    attr.dates.push({ dateType: k, date: v, dateInformation: null });
  }

  addDate('Created', attr.created);
  addDate('Issued', attr.updated || attr.created);
  addDate('Submitted', attr.updated || attr.created);
  if (attr.updated) { addDate('Updated', attr.updated); }

  return attr;
};


export default EX;
