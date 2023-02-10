# DALL-E history sync

As of August 2022, OpenAI did not provide a way to back up all of the images you had generated with DALL-E. This is my attempt to provide a stop-gap measure. It downloads any new generations (since the last time you ran it) along with their prompts, timestamps, relationships to other generations, and other metadata.

**This requires familiarity with HTTP and the command line.** See sync.sh for details.

I cannot provide support—I don't work for OpenAI and don't even
have access to documentation for their website's (internal) API. It
could break at any time, or do the wrong things because I didn't make
the right guess about the parameters I was seeing in the browser's
network tab.

I cannot provide support; if you want a supported option, please ask OpenAI.

2023-02-10: I've stopped playing with DALL-E and can't commit to
testing any improvements, so I'm archiving the repo. Check the list of
recently updated forks to see if there's a maintained version:
https://github.com/timmc/dalle-history-sync/network
