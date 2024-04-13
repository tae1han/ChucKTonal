///////////////////////////////////////////////////////////////////////
// EZscore Demo 1: 
// Combining EZchord, EZscale, EZscore
//
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

// Here I will demo some tools that help write music in ChucK using pitches, rhythms, chords, and scales
// Here's how you might build up a simple song with EZscore
//---------------------------------------------------------------------

// Let's start with a simple bassline:
EZscore bassline("[k1s c3 c b b a a g g a b]", "[h.x6 h. qx3]");

// Playback setup
120 => int bpm;

ScorePlayer part(bassline, bpm, .2);
// part.play();

//---------------------------------------------------------------------
// Now let's use EZchord to make a short chord progression

// four-chord progression
EZchord arp1("Emin", 4);
EZchord arp2("D", 4);
EZchord arp3("C", 4);
EZchord arp4("Bmin", 3);

EZscore arp([arp1.notes, arp2.notes, arp3.notes, arp4.notes, arp4.notes, arp3.notes, arp2.notes], "[w.x3 h. qx3]");

// First, let's hear those chords
part.init(arp);
// part.play();

// Now let's arpeggiate each chord
arp.arpeggiate(1.0/3.0, 1);
part.init(arp);
// part.play();

//---------------------------------------------------------------------
// Let's add more chords!

EZchord chord1("Cmaj9", 4);
EZchord chord2("Bmin7", 3);
EZchord chord3("Amin9", 3);
EZchord chord4("Gmaj9", 3);

EZscore chords([chord1.notes, chord2.notes, chord3.notes, chord4.notes], "[w.x4]");
part.init(chords);
// part.play();

//---------------------------------------------------------------------
// Here's a longer melody that we can put on top:

EZscore topline("[k1s b4 b b r//b d r gd//g a b b r//b b b b//a g r r d//e g a//d b r//g a b]","[tq te q q//q q tq te//tex3 q q//tq te q q//tq te q tq te//q q q//tq te h//qx3]");

part.init(topline);
// part.play();


// Okay, now time to put it all together!

//---------------------------------------------------------------------
// Full Playback Setup
//---------------------------------------------------------------------

ScorePlayer part1(arp, bpm, .15);
ScorePlayer part2(bassline, bpm, .1);
ScorePlayer part3(chords, bpm, .05);
ScorePlayer part4(topline, bpm, .25);

repeat(1)
{
    spork~part1.play();
    spork~part2.play();
    (topline.totalDuration / bpm)::minute => now;
}
repeat(2)
{
    spork~part1.play();
    spork~part2.play();
    spork~part3.play();
    spork~part4.play();
    (topline.totalDuration / bpm)::minute => now;
}

//---------------------------------------------------------------------
// Let's mess with the sequences we wrote:

// Define a scale as reference
EZscale scale("major", "G");

// harmonize the bassline
bassline.harmonize(4, scale.notes, 1);
bassline.harmonize(3, scale.notes);
// arpeggiate it and drop an octave
bassline.arpeggiate(1.0, 0);
bassline.transpose(-12);
part2.init(bassline);

// take the chords part and arpeggiate it
chords.arpeggiate(1.0/3.0, 6.0, 2);
// turn notes into rests with given probability
chords.swisscheese(.3);
part3.init(chords);

repeat(3)
{
    // play our bassline and arpeggiated chords
    spork~part2.play();
    spork~part3.play();
    (topline.totalDuration / bpm)::minute => now;

    // each repeat, harmonize the arp
    chords.harmonize(5, scale.notes);
    // shuffle the rhythms
    chords.shuffle(1);
    part2.init(bassline);
    part3.init(chords);
}

// harmonize the melody
EZscale penta("majpentatonic", "G");
topline.transpose(12);
//topline.harmonize(-2, penta.notes);
part4.init(topline, .22);
part3.init(chords, .04);

// vamp forever :D
while(true)
{
    spork~part2.play();
    spork~part3.play();
    spork~part4.play();
    (topline.totalDuration / bpm)::minute => now;
}