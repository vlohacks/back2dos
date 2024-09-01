# Part 02: Dreamit Operating System Reimplementation
Once upon a time there was DREAMIT.MOD. For some reasons this tune really annoyed a former friend of mine so much that another former friend and I put some serious effort in confronting him with this song. 

Recently I stumbled upon a silly program I wrote in BASIC (the language of my choice back these days) which asked the question if you like to listen to DREAMIT. You had 3 buttons: Yes, No, Exit. But of course regardless of which button you click it anyways plays the song! I called the thing DOS back then (Dreamit Operating System). And yeah, I put a lot of effort in designing fancy GUIs with ASCII graphics. Having Mouse support in BASIC was a big thing for be back then. So much that I completely forgot about keyboard support - maybe a thing which I should implement in the new version some day (currently you need a mouse - also in the new version).
On the other hand when I was a kid, it was beyond my knowledge including a MOD player library along with my BASIC code. So I went with the lame approach just starting an external MOD player using the SYSTEM command.
Of course it was not a real OS but Windows 3.1 wasn't either and microsoft called it Operating System ;-).

Also back these days it was always a dream of mine coding my own demos or my own MOD player etc. but my knowledge was limited back in 1995. So what is the most obvious thing to do with a useless programm like this? Of course rewriting it in a way I would have done it with todays knowhow! Which language to choose? Hmm. C would be a quite obvious choise but... Around the same time when I initially coded this, I bought a copy of Turbo Assembler 4.0 from MediaMarkt (A discounted offer from german book publisher Franzis' - but 49 Deutsche Mark were still a shiload of money!) to finally write FAST code! But got never beyond Hello World in 1995... Therefore... why not rewriting the whole thing in pure assembly? Because what is better than rewriting a useless programm for an obsolete OS in 2024? Yeah, choosing the hardest and most tedious way in accomplishing that task! I opted for my original copy of Turbo Assembler 4.0 (Yeah I still have the CD-ROM!) in a DOS virtual machine with just EDIT as my code editor.

However writing my own MOD playback routines in ASM was beyond my scope. So I went with MIDAS (nowadays called Housemarque Sound System) which comes with SB output and MOD/S3M playback routines. Kudos to the Sahara Surfers!
You can get MIDAS from here: http://s2.org/midas/ . I used the Release 0.40, the oldest release on the page since this version supports assembly language and real mode. Yes it is not recommended for new developers, but hey, I am an old developer :-D

three evenings and ~1000 lines of assembly later here it is! The 2024 release of DOS (Dreamit Operating System) which resembles the look and feel of the original with some few improvements like a shiny integrated MOD player! There is however some room for optimization, some things I keep here which are already in my mind now:

* cautious handling of segments: no need to keep ES safe all the time?
* Maybe pointing ES always to video memory can save some bytes
* MOD player screen updates juggle with segment registers (due to MIDAS' far pointers) a lot which might be done better 
* Len function use DS instead of ES? For no need to save ES while determining string lenghts in GUI operations.

The assembler code uses nearly the same function names like in the BASIC version for direct reference. I also put up the old BASIC code along with it in the ORIGINAL dir.

## FileZ
* DREAMIT.ASM: The full source code featuring excellent documentation. 
* DREAMIT.MOD: The tune
* DREAMIT.EXE: Ready to run DOS executable
* MAKEFILE: Makefile for building and linking with MIDAS
* ORIGINAL/DOS11.BAS: Original BASIC source
* ORIGINAL/DOS11.EXE: Original ready to run EXE
* ORIGINAL/DREAMIT.MOD: The tune again (must reside along with the EXE)
* ORIGINAL/DMP.EXE: The external MOD player I used back then.

## Toolz Hall of Fame 
* Turbo Assembler 4.0 (TASM + TLINK)
* DOS EDIT
* MIDAS 0.40a

