///////////////////////////////////////////////////////////////////////
// EZ score example - sequence modulation
// 
// NOTE: requires ezscore.ck ezchord.ck scoreplayer.ck
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

// Initializing a melody
//---------------------------------------------------------------------

EZscore melody("[k0 c d e f g a b c]", "[qx2 e. s tex3 q]");
EZscale scale("major", "C");

//---------------------------------------------------------------------
// Playback setup
//---------------------------------------------------------------------

120 => int bpm;
ScorePlayer player(melody, bpm, .1);
player.play();

//---------------------------------------------------------------------
// Modulations and variations
//---------------------------------------------------------------------

repeat(3)
{
    melody.harmonize(2, scale.notes);
    melody.shuffle(1);
    melody.transpose(3);
    melody.reverse();
    player.init(melody);
    player.play();

    melody.reverse();
    melody.shuffle(2);
    melody.transpose(-2);
    player.play();

    melody.arpeggiate(.25);
    melody.swisscheese(.25);
    melody.transpose(-1);
    player.init(melody);
    player.play();
}

