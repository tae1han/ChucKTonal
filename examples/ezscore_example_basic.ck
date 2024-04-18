///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
// Tutorial examples
//
// This file contains snippets meant to help learn the EZscore system 
// of note entry. For more detailed documentation, please visit 
// https://ccrma.stanford.edu/~alexhan/ChucKTonal/
//
// EZscore allows for the entry of notes to create melody streams
// that can then be used for easy playback. Each EZscore object is
// initialized using a pitch string and rhythm string. The sequence 
// length can be arbitrarily long, but beware: the length of pitch and 
// rhythm sequences must match!
// 
// After initialization, the EZscore object will have the pitches
// in the form of MIDI numbers, and the rhythms in the form of floats
// (representing multiples of one beat)
//
// This example code will show how to use different features of the 
// EZscore system.
//
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
// Basic Melody entry
//
// start by writing a pitch sequence and a rhythm sequence:

// Pitch:
// entered using normal 12-tone pitch names, separated by spaces:

"[c c g g a a g]" @=> string pitches;

// Rhythm:
// entered using 1-character shorthand
// q = quarter
// h = half
// w = whole
// e = eighth
// s = sixteenth

"[q q q q q q h]" @=> string rhythms;

// Then, create an EZscore object, and using .setPitch() and .setRhythm() to initialize

EZscore melody;
melody.setPitch(pitches);
melody.setRhythm(rhythms);

// To check the contents of the melody, call .printContents()
// melody.printContents();
// // Use .printPitches() to check just the MIDI note numbers
// melody.printPitches();
// // Use .printRhythms() to check just the note rhythms in beats
// melody.printRhythms();

// For the subsequent examples, try reassigning the pitch/rhythm sequence
// using melody.setPitch() or melody.setRhythm(), then calling melody.printContents
// to see the effect!

///////////////////////////////////////////////////////////////////////
// More on Pitch entry
// 
// Accidentals
// -----------------------
// Use the characters 'f' and 's' for flats and sharps, respectively.
// Use 'n' for natural
// Double-flats use 'ff' or 'ss'. 

// Twinkle twinkle in Db:
"[df df af af bf bf af]" @=> string pitches_Db;
// melody.setPitch(pitches_Db);
// melody.printContents();

// Key signatures
// -----------------------
// To set a key signature, add a 3 character code to the start of the 
// pitch string. The format should be 'kNX', where N is a number of
// sharps or flats, and X indicates sharps ('s') or flats ('f')
// In the example below, 'k4f' means "key four flats", a.k.a Ab major.  
"[k4f a a e e f f e]" @=> string pitches_Ab;
// melody.setPitch(pitches_Ab);
// melody.printContents();

// Octaves
// -----------------------
// octaves can be explicitly set by simply adding the octave number 
// after the pitch name:

"[c5 c g5 g a a g]" @=> pitches;
// melody.setPitch(pitches);
// melody.printContents();

// Direction flags
// -----------------------
// the characters 'u' and 'd' (up and down, respectively) can be used to 
// force octaves based on whether the note should be higher or lower than
// the previous note. Multiple octave jumps can be used with 'uu', 'ddd' etc.

"[c3 cu g g auu a gd]" @=> string jump_octaves;
// melody.setPitch(jump_octaves);
// melody.printContents();

// Proximity
// -----------------------

// Once an octave has been set, subsequent notes do not need to be
// explicitly set. Notes are assumed to be in the octave that puts them 
// closest to the previous note.

// NOTE: this means that this:
"[g4 a b c d e fs]" @=> string gMajor;
// represents an ascending scale and doesn't jump down when crossing the 
// octave boundary between B and C.
// melody.setPitch(gMajor);
// melody.printContents();

///////////////////////////////////////////////////////////////////////
// More on Rhythm entry

// Use the '.' character after the rhythm to indicate dotted rhythms of any resolution:
"[q. q. q.. q.. e. e. s..]" @=> string dotted;

// melody.setPitch(pitches);
// melody.setRhythm(dotted);
// melody.printContents();


// Use the character 't' before the rhythm to indicate triplets
"[te te te tq tq tq th]" @=> string triplets;

// melody.setRhythm(triplets);
// melody.printContents();

// Dotted triplets are possible
"[te. te. te. tq. tq. tq. th..]" @=> string dottedTriplets;

// melody.setRhythm(dottedTriplets);
// melody.printContents();

///////////////////////////////////////////////////////////////////////
// Repeat shortcut

// Both pitches and rhythms can be repeated to speed up entry 
// using the 'x' character followed by a number of repetitions.

"[cx2 dx4 ex8]" @=> string pitch_repeat;
"[qx2 e.x4 tsx8]" @=> string rhythm_repeat;

// melody.setPitch(pitch_repeat);
// melody.setRhythm(rhythm_repeat);
// melody.printContents();

///////////////////////////////////////////////////////////////////////
// Chord entry

// Chords can be entered in the pitch sequence by joining notes with 
// the ':' character. Normal pitch entry/format rules apply

"[c3:e:g c:f:a d:f:g:b c:e:g:cu]" @=> string chords;

// melody.setPitch(chords);
// melody.setRhythm("[qx4]");
// melody.printContents();

// NOTE: EZscore pitch arrays are 2D, indexed first by position in the 
// sequence, then in ascending order in the chord. A monophonic melody
// that is N notes long would have dimensions Nx1
//
// A polyphonic sequence like the chords above would be parsed as a 
// jagged 2D array

///////////////////////////////////////////////////////////////////////
// Ties

// Ties can be inserted by including the symbol '_' in both the pitch and 
// rhythmm strings. When parsed, the tied note's duration gets added to the 
// previous note's duration, and the corresponding pitch is ignored.

"[c4 c g g a a _a g]" @=> string pitchesTied;
"[q q q q q q _e q]" @=> string rhythmTied;

// melody.setPitch(pitchesTied);
// melody.setRhythm(rhythmTied);
// melody.printContents();