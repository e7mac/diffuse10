diffuse10
=========

Vision
======
I have been wondering about the process of writing music in 8 channels. It is going to be very different from writing even stereo music as there are so many more dimensions to think of. I wanted to facilitate the exploration of 8 channel music creation and recording.

Technical Details
=================
The GUI is in Processing using the OSCpack and Control Libraries and on iOS using the vvOSC library. The 8 channel audio routing is done through ChucK. Communication between the 2 scripts are handled through osc messages.


UX
==
diffuse10 allows the user to load loops and then control the spatialization of that loop's sound by simply clicking inside a polygon. The polygon represents the space inside an 8-channel environment where each vertex represents a speaker. The user can also switch loops off, control the levels of different loops and also apply either a pan8 or a drunkenWalk effect. Pan8 makes the sound move circularly and drunkenWalk makes the sound move randomly inside the 8-channel space.
