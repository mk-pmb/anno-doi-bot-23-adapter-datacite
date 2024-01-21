
Hints for using the DataCite API
================================


API error: Invalid metadata
---------------------------

The [DataCite API docs on updating DOIs
](https://support.datacite.org/docs/updating-metadata-with-the-rest-api)
claim for a lot of fields that they can be updated,
including `rightsList` and `publicationYear`,
but it only works for some of [our fixtues](../test/fixtures/).

For the `doibot-datacite-test-240126-*` fixtures,
we can PUT the resulting `*.dcmeta.json` as often as we want and it will
always succeed.

However, for the `esau-rsterr_*` fixtures, only the initial PUT
succeed. When we PUT them again, it reliably triggeres the error
`{ "source": "metadata", "title": "Is invalid", … }`.

__Failing attributes:__
To avoid it, I had to omit these attributes:

* `alternateIdentifiers`
* `creators`
* `dates`
* `language`
* `publicationYear`
* `rightsList`
* `titles`
* `types`

__Acceptable attributes:__
Thus, updates seem to be limited to these attributes:

* `created` (but we probably shouldn't until we can also update `dates`)
* `doi`
* `relatedIdentifier`
* `schemaVersion`
* `subjects`
* `url`





