# Change Log

## vx.x.x - ???
  * update Docu
  * parent (instead of base)
  * add CLI binaries (to compile + upload) -> read from .adyenrc file
  * make compatible with Live system

## v0.0.12 - 2-05-2012
  * fixed missing path when folder doesn't match `name-code` pattern

## v0.0.12 - 23-04-2012
  * renamed `compile` to `compress`
  * added `compile` which splits any given input to the inc/* file according to given pattern
  * parse metafile
  * log out on AuthError
  * cache all skins, only load remote when authorized

## v0.0.7
  * fix download issue
  * fix name with multiple - issue
  * added decompile with backup

## v0.0.4
  * get the default path right
  * add path to remote skins
  * freeze local skins by default

## v0.0.3
  * force update remote
  * .all unions remote + local (no more duplicates)
  * freeze locals to indicate missing remote endpoint
  * raise exception when page could not be loaded

## v0.0.2
  * cleanup
  * dep. fix

## v0.0.1 - 10-04-2012
  _inital release_

  * basic Skin manipulations
