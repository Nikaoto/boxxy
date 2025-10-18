#! /bin/bash

if [[ "$OSTYPE" == "darwin"* ]]
then
    DYLD_FALLBACK_LIBRARY_PATH="$PWD/src/engine/clibs/osx:$DYLD_FALLBACK_LIBRARY_PATH" /Applications/love.app/Contents/MacOS/love src $@
else
    LD_LIBRARY_PATH="$PWD/src/engine/clibs/linux:$LD_LIBRARY_PATH" love src $@
fi
