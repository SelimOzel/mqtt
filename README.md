mqtt
=============

MQTT broker written in D, using vibe.d.

Doesn't yet implement all of MQTT. It's possible to subscribe but not unsubscribe,
and QOS levels different from 0 are not implemented.

Needs vibe.d. The easiest way to build is by using
[dub](https://github.com/rejectedsoftware/dub).

Running the executable makes the server listen on port 1883.