SELECT CONCAT('wget ''', "url", ''' -O ''',
  "base_id", '~', "version_num", '''.json') AS "cmd"
FROM "anno_links" WHERE "rel" = 'doi';


SELECT "url" FROM "anno_links" WHERE "rel" = 'doi';


SELECT CONCAT('wget ''http://localhost:33321/anno/',
  "base_id", '~', "version_num", ''' -O ''',
  "base_id", '~', "version_num", '''.json') AS "cmd"
FROM "anno_links" WHERE "rel" = 'doi';



-- -*- coding: UTF-8, tab-width: 2 -*-
