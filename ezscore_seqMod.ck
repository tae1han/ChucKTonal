///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
// Tutorial examples - Playback and multi-part scores
//
// This file contains a ScorePlayer class meant to facilitate playback
// of EZscore objects. It also allows for stacking of multiple parts 
// to be played simultaneously.
//
// Alex Han 2024
///////////////////////////////////////////////////////////////////////

// Custom class for EZscore playback

class ScorePlayer
{
    EZscore score;
    int pitches[][];
    float rhythms[];

    int n_voices;
    SinOsc oscs[];
    ADSR envs[];
    Gain bus;
    .25 => float mix;
    120 => float local_bpm;

    fun ScorePlayer(EZscore s)
    {
        init(s);
    }

    fun void init(EZscore s)
    {
        s @=> score;
        s.n_voices => n_voices;
        s.pitches @=> pitches;
        s.rhythms @=> rhythms;
        init_sound();
    }

    fun void init_sound()
    {
        SinOsc temp_oscs[n_voices] @=> oscs;
        ADSR temp_envs[n_voices] @=> envs;
        bus.gain(mix);
        for (int i; i < n_voices; i++)
        {
            oscs[i] => envs[i] => bus => dac;
            oscs[i].gain(1.0/(n_voices $ float));
            envs[i].set(10::ms, 500::ms, 0.0, 50::ms);
        }
    }

    fun void level(float m)
    {
        m => mix;
        init_sound();
    }
    
    fun void playNote(int which, int note, float duration)
    {
        if(note >= 0)
        {
            Std.mtof(note) => oscs[which].freq;
            envs[which].keyOn();
        }
    }

    fun void play()
    {
        //need to also check that the note and duration streams are the same length
        for(int i; i < pitches.size(); i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                spork ~ playNote(j, pitches[i][j], rhythms[i]);
            }
            60*rhythms[i]/local_bpm => float durTime;
            durTime::second => now;
        }
    }

    fun void printPitches()
    {
		<<<"# of pitches: ", pitches.size()>>>;
        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for(auto p : curr)
            {
                <<<p>>>;
            }

        }
    }

    fun void printRhythms()
    {   
		<<<"# of rhythms: ", rhythms.size()>>>;
        for(auto r : rhythms)
        {
            <<<r>>>;
        }
    }

}

//---------------------------------------------------------------------
// Combining EZchord, EZscale, EZscore
//---------------------------------------------------------------------

// Melody 1
//---------------------------------------------------------------------
// four-chord progression
EZchord chord1("Abmaj9", 3);
EZchord chord2("G7#9b13", 3);
EZchord chord3("Cmin11", 3);
EZchord chord4("Ebsus9", 3);
chord4.inversion(2);

EZscore melody1([chord1.notes, chord2.notes, chord3.notes, chord4.notes]);
melody1.speed(.5);

// Arpeggiator
melody1.arpeggiate(.25, 4.0);

// Harmonization
EZscale scale("minor", "C");
melody1.harmonize(5, scale.notes, 1);
melody1.harmonize(4, scale.notes, -1);
melody1.swisscheese(.4);
melody1.printPitchRhythm();

// Melody 2
//---------------------------------------------------------------------
EZscore bassline("[k3f a2 g c e]", "[w w w w]");
bassline.uzi(16);
//melody2.printPitchRhythm();

// Melody 3
//---------------------------------------------------------------------
EZscore topline("[k3f b5 c e f g e f g r//b5 c e f g f r c f e]","[sx4 e e e. s q//sx4 sx4 q q]");

//---------------------------------------------------------------------
// Playback setup
//---------------------------------------------------------------------

110 => int bpm;

ScorePlayer player1(melody1);
ScorePlayer player2(bassline);
ScorePlayer player3(topline);
player1.level(.1);
player2.level(.05);
player3.level(.2);
bpm => player1.local_bpm;
bpm => player2.local_bpm;
bpm => player3.local_bpm;

//---------------------------------------------------------------------
// Modulations and variations
//---------------------------------------------------------------------

spork~player1.play();
spork~player2.play();
spork~player3.play();

repeat(3)
{
    player1.play();
    melody1.shuffle(1);
}
// repeat(4)
// {
//     melody1.shuffle();
//     player1.play();
//     melody1.transpose(3);
// }


while(true)
{
    1::second => now;
}