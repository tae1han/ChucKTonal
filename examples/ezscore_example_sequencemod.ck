///////////////////////////////////////////////////////////////////////
// EZ score example
// 
// NOTE: requires ezscore.ck ezchord.ck scoreplayer.ck
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------
// Combining EZscore, EZchord
//---------------------------------------------------------------------

// Initializing a melody using chords
//---------------------------------------------------------------------
// four-chord progression
EZchord chord1("Abmaj9", 3);
EZchord chord2("G7#9b13", 3);
EZchord chord3("Cmin11", 3);
EZchord chord4("Ebsus9", 3);
chord4.inversion(2);

EZscore melody([chord1.notes, chord2.notes, chord3.notes, chord4.notes]);
melody.speed(.5);

// Arpeggiator
melody.arpeggiate(.25, 4.0, 2);

//---------------------------------------------------------------------
// Playback setup
//---------------------------------------------------------------------

110 => int bpm;
ScorePlayer player(melody, bpm, .1);

// play the melody as-is
player.play();

//---------------------------------------------------------------------
// Modulations and variations
//---------------------------------------------------------------------

repeat(4)
{
    player.play();
    melody.shuffle(1);
    melody.transpose(3);
    melody.reverse();
    melody.shorten(2);
    player.play();
    melody.reverse();
    
    melody.shuffle(2);
    melody.transpose(-2);
    player.play();
    melody.swisscheese(.25);
    melody.shorten(2);
    melody.transpose(-1);
}

