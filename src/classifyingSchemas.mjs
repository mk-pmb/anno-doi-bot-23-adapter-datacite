// -*- coding: utf-8, tab-width: 2 -*-

function byUrlPrefix(url) {
  const prefix = Object.keys(byUrlPrefix).find(k => url.startsWith(k));
  return (prefix ? { prefix, parse: byUrlPrefix[prefix] } : false);
}

const EX = {
  byUrlPrefix,
};

function reg(urlPrefixes, func) {
  Object.assign(func, { urlPrefixes });
  EX[func.name] = func;
  urlPrefixes.forEach((p) => { EX.byUrlPrefix[p] = func; });
}

reg(['https://d-nb.info/gnd/'], function gnd(ctx) {
  ctx.state.report.gndSubjects.push({
    subject: ctx.title,
    schemeUri: ctx.prefix,
    subjectScheme: 'GND',
    classificationCode: ctx.subUrl,
  });
});


export default EX;
